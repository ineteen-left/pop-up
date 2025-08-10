import SwiftUI
import MapKit
import PhotosUI
import CoreLocation

// MARK: - Helper Functions
func checkChineseLocale() -> Bool {
    let preferredLanguage = Locale.preferredLanguages.first ?? ""
    print("Preferred Language: \(preferredLanguage)") // Debug print
    return preferredLanguage.hasPrefix("zh") || preferredLanguage.hasPrefix("zh-Hans") || preferredLanguage.hasPrefix("zh-Hant")
}

// MARK: - Main App Structure
// Note: @main is defined in pop_upApp.swift

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}


// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isChineseLocale = checkChineseLocale()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 10) {
                        Text(isChineseLocale ? "弹窗画廊" : "PopUp Gallery")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isChineseLocale ? "连接艺术家与空间" : "Connect artists with spaces")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Email/Password Sign In
                    VStack(spacing: 20) {
                        TextField(isChineseLocale ? "邮箱" : "Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField(isChineseLocale ? "密码" : "Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(isSignUp ? (isChineseLocale ? "注册" : "Sign Up") : (isChineseLocale ? "登录" : "Sign In")) {
                            if isSignUp {
                                authManager.signUp(email: email, password: password, userType: .artist)
                            } else {
                                authManager.signIn(email: email, password: password)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(email.isEmpty || password.isEmpty)
                        
                        Button(isSignUp ? 
                               (isChineseLocale ? "已有账户？登录" : "Already have an account? Sign In") : 
                               (isChineseLocale ? "没有账户？注册" : "Don't have an account? Sign Up")) {
                            isSignUp.toggle()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    if isSignUp {
                        Text(isChineseLocale ? "注册后您可以选择成为艺术家或商业场所主！" : "You can choose to be an Artist or Business Owner after signing up!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
    }
}


// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isChineseLocale = checkChineseLocale()
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Image(systemName: "map")
                    Text(isChineseLocale ? "探索" : "Explore")
                }
            
            MyListingsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(isChineseLocale ? "我的列表" : "My Listings")
                }
            
            CreateListingView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(isChineseLocale ? "发布" : "Create")
                }
            
            MessagesView()
                .tabItem {
                    Image(systemName: "message")
                    Text(isChineseLocale ? "消息" : "Messages")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text(isChineseLocale ? "个人资料" : "Profile")
                }
        }
    }
}

// MARK: - Explore View (Map + List)
struct ExploreView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingList = false
    @State private var searchText = ""
    @State private var filterType: FilterType = .all
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Bar
                HStack {
                    TextField("Search locations or artists...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Filter", selection: $filterType) {
                        Text("All").tag(FilterType.all)
                        Text("Spaces").tag(FilterType.spaces)
                        Text("Artists").tag(FilterType.artists)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)
                
                // Toggle between Map and List
                Picker("View", selection: $showingList) {
                    Text("Map").tag(false)
                    Text("List").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if showingList {
                    ListingsListView(searchText: searchText, filterType: filterType)
                } else {
                    MapView(searchText: searchText, filterType: filterType)
                }
            }
            .navigationTitle("Explore")
        }
    }
}

// MARK: - Map View
struct MapView: View {
    let searchText: String
    let filterType: FilterType
    @StateObject private var mapData = MapDataManager()
    
    var body: some View {
        Map(coordinateRegion: $mapData.region, annotationItems: mapData.filteredListings(searchText: searchText, filterType: filterType)) { listing in
            MapAnnotation(coordinate: listing.coordinate) {
                ListingMapPin(listing: listing)
            }
        }
        .onAppear {
            mapData.loadListings()
        }
    }
}

struct ListingMapPin: View {
    let listing: Listing
    
    var body: some View {
        VStack {
            Image(systemName: listing.type == .space ? "building.2" : "paintpalette")
                .foregroundColor(.white)
                .padding(8)
                .background(listing.type == .space ? Color.blue : Color.purple)
                .clipShape(Circle())
            
            Text(listing.title)
                .font(.caption)
                .padding(4)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 2)
        }
    }
}

// MARK: - Listings List View
struct ListingsListView: View {
    let searchText: String
    let filterType: FilterType
    @StateObject private var listingsManager = ListingsManager()
    
    var body: some View {
        List(listingsManager.filteredListings(searchText: searchText, filterType: filterType)) { listing in
            NavigationLink(destination: ListingDetailView(listing: listing)) {
                ListingRowView(listing: listing)
            }
        }
        .onAppear {
            listingsManager.loadListings()
        }
    }
}

struct ListingRowView: View {
    let listing: Listing
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: listing.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                
                Text(listing.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: listing.type == .space ? "building.2" : "paintpalette")
                    Text(listing.type == .space ? "Space" : "Artist")
                    Spacer()
                    if listing.type == .space {
                        Text("$\(listing.price ?? 0)/day")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Listing Detail View
struct ListingDetailView: View {
    let listing: Listing
    @State private var showingContactSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image Gallery
                AsyncImage(url: URL(string: listing.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 250)
                .clipped()
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(listing.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "location")
                        Text(listing.location)
                        Spacer()
                        if listing.type == .space {
                            Text("$\(listing.price ?? 0)/day")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    Text(listing.description)
                        .font(.body)
                    
                    if listing.type == .space {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Space Details")
                                .font(.headline)
                            
                            Label("Size: \(listing.spaceSize ?? "Not specified")", systemImage: "ruler")
                            Label("Available: \(listing.availableDates ?? "Contact for dates")", systemImage: "calendar")
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Artist Info")
                                .font(.headline)
                            
                            Label("Style: \(listing.artStyle ?? "Mixed")", systemImage: "paintpalette")
                            Label("Looking for: Gallery space", systemImage: "magnifyingglass")
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Contact") {
                    showingContactSheet = true
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingContactSheet) {
            ContactView(listing: listing)
        }
    }
}

// MARK: - Contact View
struct ContactView: View {
    let listing: Listing
    @State private var message = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Send a message to")
                        .font(.headline)
                    Text(listing.ownerName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.headline)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button("Send Message") {
                    // Handle sending message
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Create Listing View
struct CreateListingView: View {
    @State private var selectedUserType: UserType = .artist
    @State private var isChineseLocale = checkChineseLocale()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // User Type Selector - Only in Create tab
                Picker("User Type", selection: $selectedUserType) {
                    Text(isChineseLocale ? "艺术家" : "Artist").tag(UserType.artist)
                    Text(isChineseLocale ? "商业场所主" : "Business Owner").tag(UserType.business)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color(UIColor.systemGray6))
                
                // Content based on selected type
                if selectedUserType == .business {
                    BusinessListingView()
                } else {
                    ArtistPortfolioView()
                }
            }
        }
    }
}

// MARK: - Business Listing View
struct BusinessListingView: View {
    @State private var venueName = ""
    @State private var venueType = ""
    @State private var location = ""
    @State private var address = ""
    @State private var description = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var price: Int = 0
    @State private var spaceSize = ""
    @State private var seatingCapacity = ""
    @State private var availableDates = ""
    @State private var amenities: [String] = []
    @State private var venueStyle = ""
    
    let venueTypes = ["Gallery", "Restaurant", "Cafe", "Retail Space", "Event Space", "Studio", "Other"]
    let venueStyles = ["Modern", "Classic", "Industrial", "Minimalist", "Rustic", "Contemporary", "Traditional"]
    let availableAmenities = ["WiFi", "Lighting System", "Sound System", "Parking", "Kitchen", "Storage", "Security", "Restrooms"]
    
    var body: some View {
        Form {
            Section(header: Text("Venue Information")) {
                TextField("Venue Name", text: $venueName)
                
                Picker("Venue Type", selection: $venueType) {
                    ForEach(venueTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
                TextField("City/Area", text: $location)
                TextField("Full Address", text: $address, axis: .vertical)
                    .lineLimit(2...3)
            }
            
            Section(header: Text("Space Details")) {
                TextField("Space Size (sq ft)", text: $spaceSize)
                TextField("Seating Capacity", text: $seatingCapacity)
                
                Picker("Style", selection: $venueStyle) {
                    ForEach(venueStyles, id: \.self) { style in
                        Text(style).tag(style)
                    }
                }
                
                TextField("Price per day ($)", value: $price, format: .number)
            }
            
            Section(header: Text("Description")) {
                TextField("Describe your space...", text: $description, axis: .vertical)
                    .lineLimit(4...8)
            }
            
            Section(header: Text("Amenities")) {
                ForEach(availableAmenities, id: \.self) { amenity in
                    Toggle(amenity, isOn: Binding(
                        get: { amenities.contains(amenity) },
                        set: { isOn in
                            if isOn {
                                amenities.append(amenity)
                            } else {
                                amenities.removeAll { $0 == amenity }
                            }
                        }
                    ))
                }
            }
            
            Section(header: Text("Photos")) {
                PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                    Label("Upload Space Photos", systemImage: "photo.on.rectangle.angled")
                }
                
                if !selectedImages.isEmpty {
                    Text("\(selectedImages.count) photos selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Availability")) {
                TextField("Available Dates", text: $availableDates, axis: .vertical)
                    .lineLimit(2...3)
            }
            
            Section {
                Button("Create Venue Listing") {
                    createBusinessListing()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.semibold)
                .disabled(venueName.isEmpty || location.isEmpty || description.isEmpty)
            }
        }
        .navigationTitle("List Your Space")
    }
    
    private func createBusinessListing() {
        print("Creating business listing: \(venueName)")
        // Handle creating business listing with venue details
    }
}

// MARK: - Artist Portfolio View
struct ArtistPortfolioView: View {
    @State private var artistName = ""
    @State private var artStyle = ""
    @State private var medium = ""
    @State private var bio = ""
    @State private var selectedPortfolioImages: [PhotosPickerItem] = []
    @State private var selectedArtSamples: [PhotosPickerItem] = []
    @State private var experience = ""
    @State private var lookingFor = ""
    @State private var priceRange = ""
    @State private var website = ""
    @State private var instagram = ""
    
    let artStyles = ["Abstract", "Contemporary", "Traditional", "Pop Art", "Surrealism", "Expressionism", "Photography", "Sculpture", "Mixed Media"]
    let mediums = ["Oil Paint", "Acrylic", "Watercolor", "Digital Art", "Photography", "Sculpture", "Mixed Media", "Charcoal", "Pastels"]
    let experienceLevels = ["Emerging Artist", "Mid-Career", "Established", "Professional"]
    
    var body: some View {
        Form {
            Section(header: Text("Artist Information")) {
                TextField("Artist/Display Name", text: $artistName)
                
                Picker("Primary Art Style", selection: $artStyle) {
                    ForEach(artStyles, id: \.self) { style in
                        Text(style).tag(style)
                    }
                }
                
                Picker("Primary Medium", selection: $medium) {
                    ForEach(mediums, id: \.self) { medium in
                        Text(medium).tag(medium)
                    }
                }
                
                Picker("Experience Level", selection: $experience) {
                    ForEach(experienceLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
            }
            
            Section(header: Text("Bio & Artist Statement")) {
                TextField("Tell us about yourself and your art...", text: $bio, axis: .vertical)
                    .lineLimit(5...10)
            }
            
            Section(header: Text("Portfolio Images")) {
                PhotosPicker(selection: $selectedPortfolioImages, maxSelectionCount: 15, matching: .images) {
                    Label("Upload Portfolio", systemImage: "photo.on.rectangle.angled")
                }
                
                if !selectedPortfolioImages.isEmpty {
                    Text("\(selectedPortfolioImages.count) portfolio images selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Art Samples")) {
                PhotosPicker(selection: $selectedArtSamples, maxSelectionCount: 8, matching: .images) {
                    Label("Upload Recent Work Samples", systemImage: "photo.badge.plus")
                }
                
                if !selectedArtSamples.isEmpty {
                    Text("\(selectedArtSamples.count) art samples selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("What You're Looking For")) {
                TextField("Describe ideal space/collaboration...", text: $lookingFor, axis: .vertical)
                    .lineLimit(3...5)
                
                TextField("Budget/Price Range", text: $priceRange)
            }
            
            Section(header: Text("Online Presence (Optional)")) {
                TextField("Website", text: $website)
                    .autocapitalization(.none)
                TextField("Instagram Handle", text: $instagram)
                    .autocapitalization(.none)
            }
            
            Section {
                Button("Create Artist Profile") {
                    createArtistProfile()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.semibold)
                .disabled(artistName.isEmpty || artStyle.isEmpty || bio.isEmpty)
            }
        }
        .navigationTitle("Artist Profile")
    }
    
    private func createArtistProfile() {
        print("Creating artist profile: \(artistName)")
        // Handle creating artist profile with portfolio
    }
}

// MARK: - My Listings View
struct MyListingsView: View {
    @State private var myListings: [Listing] = []
    
    var body: some View {
        NavigationView {
            List(myListings) { listing in
                NavigationLink(destination: ListingDetailView(listing: listing)) {
                    ListingRowView(listing: listing)
                }
            }
            .navigationTitle("My Listings")
            .onAppear {
                loadMyListings()
            }
        }
    }
    
    private func loadMyListings() {
        // Load user's listings
    }
}

// MARK: - Messages View
struct MessagesView: View {
    @State private var conversations: [Conversation] = []
    
    var body: some View {
        NavigationView {
            List(conversations) { conversation in
                NavigationLink(destination: ChatView(conversation: conversation)) {
                    ConversationRowView(conversation: conversation)
                }
            }
            .navigationTitle("Messages")
        }
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(conversation.otherUserName.first ?? "?"))
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUserName)
                    .fontWeight(.semibold)
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(conversation.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat View
struct ChatView: View {
    let conversation: Conversation
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Chat messages would go here
                    Text("Chat implementation would go here")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    sendMessage()
                }
                .fontWeight(.semibold)
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        // Handle sending message
        messageText = ""
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(authManager.currentUser?.email.first?.uppercased() ?? "?"))
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(authManager.currentUser?.email ?? "User")
                                .font(.headline)
                            Text(authManager.currentUser?.userType.rawValue.capitalized ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    NavigationLink("Edit Profile") {
                        Text("Edit Profile View")
                    }
                    NavigationLink("Settings") {
                        Text("Settings View")
                    }
                    NavigationLink("Help & Support") {
                        Text("Help View")
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Data Models
struct User: Identifiable, Codable {
    var id = UUID()
    let email: String
    let userType: UserType
}

enum UserType: String, CaseIterable, Codable {
    case artist = "artist"
    case business = "business"
}

struct Listing: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let location: String
    let coordinate: CLLocationCoordinate2D
    let imageURL: String
    let type: ListingType
    let ownerName: String
    let price: Int?
    let spaceSize: String?
    let availableDates: String?
    let artStyle: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location, imageURL, type, ownerName, price, spaceSize, availableDates, artStyle
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        location = try container.decode(String.self, forKey: .location)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        type = try container.decode(ListingType.self, forKey: .type)
        ownerName = try container.decode(String.self, forKey: .ownerName)
        price = try container.decodeIfPresent(Int.self, forKey: .price)
        spaceSize = try container.decodeIfPresent(String.self, forKey: .spaceSize)
        availableDates = try container.decodeIfPresent(String.self, forKey: .availableDates)
        artStyle = try container.decodeIfPresent(String.self, forKey: .artStyle)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(location, forKey: .location)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(type, forKey: .type)
        try container.encode(ownerName, forKey: .ownerName)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(spaceSize, forKey: .spaceSize)
        try container.encodeIfPresent(availableDates, forKey: .availableDates)
        try container.encodeIfPresent(artStyle, forKey: .artStyle)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    init(title: String, description: String, location: String, coordinate: CLLocationCoordinate2D, imageURL: String, type: ListingType, ownerName: String, price: Int? = nil, spaceSize: String? = nil, availableDates: String? = nil, artStyle: String? = nil) {
        self.title = title
        self.description = description
        self.location = location
        self.coordinate = coordinate
        self.imageURL = imageURL
        self.type = type
        self.ownerName = ownerName
        self.price = price
        self.spaceSize = spaceSize
        self.availableDates = availableDates
        self.artStyle = artStyle
    }
}

enum ListingType: String, CaseIterable, Codable {
    case space = "space"
    case artist = "artist"
}

enum FilterType: String, CaseIterable {
    case all = "all"
    case spaces = "spaces"
    case artists = "artists"
}

struct Conversation: Identifiable {
    let id = UUID()
    let otherUserName: String
    let lastMessage: String
    let timestamp: Date
}

// MARK: - Managers
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    func signIn(email: String, password: String) {
        // Simple sign in - user type can be changed in the app
        currentUser = User(email: email, userType: .artist)
        isAuthenticated = true
    }
    
    func signUp(email: String, password: String, userType: UserType) {
        // Simple sign up - user type can be changed in the app
        currentUser = User(email: email, userType: userType)
        isAuthenticated = true
    }
    
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = checkChineseLocale() ? "需要位置权限才能显示附近的画廊" : "Location access needed to show nearby galleries"
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if the location is accurate enough
        if location.horizontalAccuracy <= 100 {
            DispatchQueue.main.async {
                self.location = location
                self.locationError = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = checkChineseLocale() ? 
                "获取位置失败" : "Failed to get location"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
                self.locationError = nil
            case .denied, .restricted:
                self.locationError = checkChineseLocale() ? 
                    "请在设置中开启位置权限" : "Please enable location access in Settings"
            case .notDetermined:
                self.requestLocationPermission()
            @unknown default:
                break
            }
        }
    }
    
    // Helper function to get address from coordinates
    func getAddress(from location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let address = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
}

class MapDataManager: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var listings: [Listing] = []
    
    func loadListings() {
        // Sample data - replace with actual API calls
        listings = [
            Listing(
                title: "Modern Gallery Space",
                description: "Beautiful modern space perfect for art exhibitions",
                location: "Downtown SF",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                imageURL: "https://example.com/space1.jpg",
                type: .space,
                ownerName: "Sarah Johnson",
                price: 150,
                spaceSize: "1200 sq ft",
                availableDates: "March 15-30"
            ),
            Listing(
                title: "Contemporary Paintings",
                description: "Abstract and contemporary artwork looking for exhibition space",
                location: "Mission District",
                coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4094),
                imageURL: "https://example.com/art1.jpg",
                type: .artist,
                ownerName: "Alex Chen",
                artStyle: "Contemporary Abstract"
            )
        ]
    }
    
    func filteredListings(searchText: String, filterType: FilterType) -> [Listing] {
        var filtered = listings
        
        if filterType != .all {
            filtered = filtered.filter { listing in
                switch filterType {
                case .spaces:
                    return listing.type == .space
                case .artists:
                    return listing.type == .artist
                case .all:
                    return true
                }
            }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { listing in
                listing.title.localizedCaseInsensitiveContains(searchText) ||
                listing.location.localizedCaseInsensitiveContains(searchText) ||
                listing.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
}

class ListingsManager: ObservableObject {
    @Published var listings: [Listing] = []
    
    func loadListings() {
        // Load listings from API
        let mapData = MapDataManager()
        mapData.loadListings()
        self.listings = mapData.listings
    }
    
    func filteredListings(searchText: String, filterType: FilterType) -> [Listing] {
        let mapData = MapDataManager()
        return mapData.filteredListings(searchText: searchText, filterType: filterType)
    }
}

// MARK: - Preview Provider
#Preview {
    ContentView()
        .environmentObject(AuthManager())
}

#Preview("Authentication") {
    AuthenticationView()
        .environmentObject(AuthManager())
}

#Preview("Main Tab View") {
    let authManager = AuthManager()
    authManager.isAuthenticated = true
    authManager.currentUser = User(email: "test@example.com", userType: .artist)
    
    return MainTabView()
        .environmentObject(authManager)
}
