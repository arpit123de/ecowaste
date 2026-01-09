# Home Screen Implementation Plan

## Current Status
- Splash screen: ✅ Complete (6-second dark animated theme)
- Login screen: ✅ Complete (glassmorphic with role toggle)
- Signup screen: ✅ Complete (full user/buyer registration)
- **Home screen: ⏳ Needs modernization**

---

## Design Requirements

### Theme Consistency
- Dark gradient background (same as login/splash)
- Glassmorphic cards with backdrop blur
- Green accents (#10b981)
- Material 3 design system
- Smooth animations

### Layout Structure

```
┌─────────────────────────────────────┐
│   App Bar (Gradient)                │
│   - Welcome message                 │
│   - Profile avatar                  │
│   - Notifications icon              │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│   Dashboard Summary Cards           │
│   ┌─────────┐  ┌─────────┐         │
│   │ Reports │  │ Pending │         │
│   │    12   │  │    3    │         │
│   └─────────┘  └─────────┘         │
│   ┌─────────┐  ┌─────────┐         │
│   │ Points  │  │ Impact  │         │
│   │   245   │  │  15kg   │         │
│   └─────────┘  └─────────┘         │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│   Quick Actions                     │
│   - Report Waste (FAB style)       │
│   - View Buyers                     │
│   - My Reports                      │
│   - Notifications                   │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│   Recent Activity                   │
│   - List of recent waste reports    │
│   - Pickup requests                 │
│   - Status updates                  │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│   Bottom Navigation Bar             │
│   [Home] [Reports] [Buyers] [Profile]│
└─────────────────────────────────────┘
```

---

## Features to Implement

### 1. App Bar
- **Gradient background** (dark blue → green)
- **Welcome message**: "Welcome back, [Name]!"
- **Profile avatar**: Circular with user initials or photo
- **Notifications icon**: Bell with badge count
- **Menu icon**: Hamburger for side drawer

### 2. Dashboard Summary (4 Cards)

#### Card 1: Total Reports
- Icon: Recycling symbol
- Title: "My Reports"
- Value: Number of waste reports created
- Color: Green gradient
- Animation: CountUp effect

#### Card 2: Pending Pickups
- Icon: Clock/Pending
- Title: "Pending"
- Value: Number of reports awaiting pickup
- Color: Orange gradient
- Animation: Pulse effect

#### Card 3: Eco Points
- Icon: Star/Trophy
- Title: "Eco Points"
- Value: Points earned from recycling
- Color: Gold gradient
- Animation: Shimmer effect

#### Card 4: Environmental Impact
- Icon: Leaf/Earth
- Title: "Impact"
- Value: Total kg of waste recycled
- Color: Blue gradient
- Animation: Wave effect

**Card Design**:
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(...),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ],
  ),
  child: ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(...), // Large icon
            TweenAnimationBuilder( // Animated counter
              tween: IntTween(begin: 0, end: value),
              duration: Duration(seconds: 1),
              builder: (context, value, child) {
                return Text('$value');
              },
            ),
            Text('Title'),
          ],
        ),
      ),
    ),
  ),
)
```

### 3. Quick Actions Section
- **Grid layout**: 2x2 or 3x2 grid
- **Large icons**: Material icons with glow effect
- **Action buttons**:
  1. 📸 **Report Waste** → Navigate to waste report form
  2. 🏪 **Browse Buyers** → Navigate to buyers list
  3. 📋 **My Reports** → Navigate to user's reports
  4. 🔔 **Notifications** → Navigate to notifications
  5. 📊 **Statistics** → View detailed analytics
  6. ⚙️ **Settings** → App settings

**Button Design**:
```dart
GestureDetector(
  onTap: () => onTap(),
  child: Container(
    decoration: BoxDecoration(
      color: Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Color(0xFF10b981).withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 40,
          color: Color(0xFF10b981),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  ),
)
```

### 4. Recent Activity Feed
- **Timeline view**: Vertical list with line connecting items
- **Item types**:
  - ✅ Report created
  - 🏪 Buyer showed interest
  - 📦 Pickup scheduled
  - ✨ Pickup completed
  - ⭐ Points earned

**List Item Design**:
```dart
ListTile(
  leading: CircleAvatar(
    backgroundColor: Color(0xFF10b981),
    child: Icon(Icons.check, color: Colors.white),
  ),
  title: Text(
    'Waste report submitted',
    style: TextStyle(color: Colors.white),
  ),
  subtitle: Text(
    '2 hours ago',
    style: TextStyle(color: Colors.white60),
  ),
  trailing: Icon(Icons.arrow_forward_ios, color: Colors.white30),
)
```

### 5. Bottom Navigation Bar
- **4 tabs**:
  1. 🏠 Home
  2. 📋 Reports
  3. 🏪 Buyers
  4. 👤 Profile
- **Selected tab**: Green color
- **Unselected tabs**: Gray color
- **Indicator**: Green line/dot above selected tab

---

## Buyer-Specific Features

### For Buyer Users:
Replace user dashboard with buyer-specific content:

#### Dashboard Cards:
1. **Pickup Requests** → Number of incoming requests
2. **Completed Pickups** → Number of successful pickups
3. **Rating** → Average rating from users
4. **Revenue** → Total earnings (optional)

#### Quick Actions:
1. 📨 **View Requests** → Incoming pickup requests
2. 📅 **My Schedule** → Scheduled pickups
3. 📊 **My Stats** → Detailed analytics
4. ⚙️ **Shop Settings** → Edit shop details

#### Recent Activity:
- New pickup requests
- Scheduled pickups today
- Recent ratings received

---

## Implementation Steps

### Step 1: Update Home Screen Layout
```dart
// lib/screens/home_screen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF064E3B),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardCards(),
              SizedBox(height: 24),
              _buildQuickActions(),
              SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
```

### Step 2: Fetch User Data
```dart
// Add to initState
@override
void initState() {
  super.initState();
  _loadDashboardData();
}

Future<void> _loadDashboardData() async {
  final userId = await StorageService().getUserId();
  
  // Fetch waste reports count
  final reports = await ApiService().getWasteReports(userId);
  
  // Fetch pending pickups
  final pending = reports.where((r) => r.status == 'pending').length;
  
  // Calculate eco points (example logic)
  final points = reports.length * 10;
  
  // Calculate impact (total weight)
  final totalWeight = reports.fold(0.0, (sum, r) => sum + r.weight);
  
  setState(() {
    _totalReports = reports.length;
    _pendingPickups = pending;
    _ecoPoints = points;
    _totalImpact = totalWeight;
  });
}
```

### Step 3: Create Dashboard Cards Widget
```dart
Widget _buildDashboardCards() {
  return GridView.count(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 1.2,
    children: [
      _buildStatCard(
        icon: Icons.recycling,
        title: 'My Reports',
        value: _totalReports,
        color: Color(0xFF10b981),
      ),
      _buildStatCard(
        icon: Icons.pending_actions,
        title: 'Pending',
        value: _pendingPickups,
        color: Color(0xFFf59e0b),
      ),
      _buildStatCard(
        icon: Icons.stars,
        title: 'Eco Points',
        value: _ecoPoints,
        color: Color(0xFFfbbf24),
      ),
      _buildStatCard(
        icon: Icons.eco,
        title: 'Impact',
        value: _totalImpact,
        suffix: 'kg',
        color: Color(0xFF3b82f6),
      ),
    ],
  );
}

Widget _buildStatCard({
  required IconData icon,
  required String title,
  required num value,
  String suffix = '',
  required Color color,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(height: 12),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value.toInt()),
                duration: Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Text(
                    '$value$suffix',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### Step 4: Create Quick Actions Widget
```dart
Widget _buildQuickActions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Quick Actions',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      SizedBox(height: 16),
      GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Report',
            onTap: () => Navigator.pushNamed(context, '/report'),
          ),
          _buildActionButton(
            icon: Icons.store,
            label: 'Buyers',
            onTap: () => Navigator.pushNamed(context, '/buyers'),
          ),
          _buildActionButton(
            icon: Icons.list,
            label: 'My Reports',
            onTap: () => Navigator.pushNamed(context, '/my-reports'),
          ),
          _buildActionButton(
            icon: Icons.notifications,
            label: 'Alerts',
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          _buildActionButton(
            icon: Icons.bar_chart,
            label: 'Stats',
            onTap: () => Navigator.pushNamed(context, '/stats'),
          ),
          _buildActionButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    ],
  );
}
```

### Step 5: Add API Endpoints
```dart
// lib/services/api_service.dart

Future<List<WasteReport>> getWasteReports(int userId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/waste-reports/?user=$userId'),
    headers: _headers,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.map((json) => WasteReport.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load reports');
  }
}
```

---

## Testing Checklist

### Visual Testing:
- ☐ Dashboard cards display correctly
- ☐ Glassmorphic effect works
- ☐ Animated counters work
- ☐ Quick action buttons respond to taps
- ☐ Bottom navigation highlights active tab

### Functional Testing:
- ☐ Data loads from API correctly
- ☐ Navigation works to all screens
- ☐ Buyer dashboard shows different content
- ☐ Real-time updates work
- ☐ Pull-to-refresh updates data

### Performance:
- ☐ Animations are smooth (60 fps)
- ☐ Data loads in < 2 seconds
- ☐ No memory leaks
- ☐ Scrolling is smooth

---

## Timeline Estimate

- **Dashboard Cards**: 2-3 hours
- **Quick Actions**: 1-2 hours
- **Recent Activity**: 2-3 hours
- **Bottom Navigation**: 1 hour
- **API Integration**: 2-3 hours
- **Testing & Polish**: 2-3 hours

**Total**: 10-15 hours

---

## Priority

**High Priority**: Dashboard cards and quick actions (core functionality)
**Medium Priority**: Recent activity feed (nice to have)
**Low Priority**: Advanced animations (polish)

---

## Next Steps

1. ✅ Complete signup feature (DONE)
2. ⏳ **Update home screen** (NEXT)
3. Create waste report form screen
4. Create buyers list screen
5. Create user profile screen
6. Add notifications system

**Status**: Ready to start home screen modernization!
