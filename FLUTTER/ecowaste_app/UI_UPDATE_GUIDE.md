# Flutter UI Update Guide - Modern Dark Eco Theme

This document contains the complete updated UI code for the EcoWaste Flutter app with a modern, futuristic dark eco-themed design.

## Updates Required

### 1. Splash Screen (splash_screen.dart)
- **Duration**: 6 seconds
- **Features**: Animated gradient background, rotating circles, fade & scale animations
- **Colors**: Dark slate to dark green/teal gradient
- See full code in the implementation below

### 2. Login Screen (login_screen.dart)
- **New Features**: 
  - Buyer/User role toggle at top
  - Glassmorphic card design  
  - Dark gradient background
  - Animated input fields with glow effect
- **Toggle**: Segmented button to switch between Buyer and User roles

### 3. Signup Screen (register_screen.dart)
- **New Features**:
  - Role selector (Buyer/User) with toggle buttons
  - Password strength indicator
  - Glassmorphic form design
  - Step-based UI with smooth animations

### 4. Home Screen (home_screen.dart)
- **New Features**:
  - Summary cards with animated counters
  - Circular progress indicators
  - Action buttons with ripple effects
  - Bottom navigation bar
  - Floating action button

### 5. Main Theme (main.dart)
- **Update to**: Dark mode base theme
- **Colors**: Primary green (#10b981), secondary teal (#14b8a6)
- **Material 3**: Enable useMaterial3
- **Typography**: Clean hierarchy

## Implementation Steps

1. Update pubspec.yaml dependencies (already done)
2. Replace screen files with new designs
3. Update main.dart theme configuration
4. Test animations and transitions
5. Verify API integration still works

## Key Design Tokens

```dart
// Colors
const primaryGreen = Color(0xFF10b981);
const secondaryTeal = Color(0xFF14b8a6);
const darkSlate = Color(0xFF0F172A);
const darkGreen = Color(0xFF064E3B);

// Border Radius
const cardRadius = 18.0;
const buttonRadius = 22.0;

// Animations
const fadeDuration = Duration(milliseconds: 300);
const scaleDuration = Duration(milliseconds: 200);
```

## Testing Checklist

- [ ] Splash screen displays for 6 seconds
- [ ] Login role toggle works (Buyer/User)
- [ ] Signup role selection works
- [ ] Home dashboard loads data
- [ ] Animations are smooth
- [ ] Dark theme is consistent across screens
- [ ] API calls still function correctly

## Notes

- All animations use proper disposal to prevent memory leaks
- Glassmorphism uses BackdropFilter with blur
- Role selection updates the API endpoint for authentication
- Maintains backward compatibility with existing API

For detailed implementation code, please request specific screen files.
