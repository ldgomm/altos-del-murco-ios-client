# Altos del Murco — iOS Client

Premium iOS client for **Altos del Murco**, a restaurant and outdoor-experience app built with **SwiftUI**, **Firebase**, **SwiftData**, and a feature-oriented Clean Architecture/MVVM structure.

The app lets customers explore the restaurant menu, place immediate or scheduled food orders, build adventure reservations, add food to experience plans, receive loyalty rewards, manage bookings, view featured posts, and maintain a complete customer profile.

> This repository contains the customer-facing iOS app. The admin/back-office app and Android client are separate projects.

---

## Table of Contents

- [Overview](#overview)
- [Core Features](#core-features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Main App Flow](#main-app-flow)
- [Feature Modules](#feature-modules)
- [Firebase Data Model](#firebase-data-model)
- [Local Persistence](#local-persistence)
- [Authentication and Profile Gate](#authentication-and-profile-gate)
- [Restaurant Ordering Flow](#restaurant-ordering-flow)
- [Adventure Reservation Flow](#adventure-reservation-flow)
- [Loyalty and Rewards](#loyalty-and-rewards)
- [Featured Posts](#featured-posts)
- [Theme and UI System](#theme-and-ui-system)
- [Project Structure](#project-structure)
- [Setup](#setup)
- [Firestore Indexes](#firestore-indexes)
- [Security Notes](#security-notes)
- [Testing Checklist](#testing-checklist)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Altos del Murco** is designed as a customer app for a restaurant and tourism/adventure experience business. It combines food ordering, scheduled food reservations, outdoor activities, featured media, loyalty rewards, and customer profile management in one native iOS experience.

The app is organized around five main tabs:

| Tab | Purpose |
|---|---|
| **Inicio** | Featured content, promotions, restaurant/adventure highlights, rewards, and entry points. |
| **Restaurante** | Menu browsing, item detail, cart, checkout, and restaurant orders. |
| **Experiencias** | Adventure catalog, featured packages, custom combo builder, food add-ons, and availability slots. |
| **Reservas** | Unified customer reservation/order visibility for restaurant and adventure flows. |
| **Perfil** | Customer identity, loyalty wallet, stats, profile image, theme preference, sign out, and account deletion. |

---

## Core Features

### Customer Session

- Sign in with Apple through Firebase Authentication.
- Session resolution on launch.
- Required profile completion before accessing the main app.
- Automatic session validation when the app becomes active.
- Forced sign-out when Firebase user is disabled, deleted, or has an invalid/expired token.
- Account deletion with reauthentication.

### Restaurant

- Firestore-driven restaurant menu.
- Category ordering for restaurant sections.
- Featured menu items.
- Offer price support.
- Stock-aware item quantity controls.
- SwiftData cart persistence.
- Immediate table orders.
- Scheduled food-only reservations.
- Loyalty discount preview before submission.
- Firestore transaction for same-day stock decrement.
- Order history and status display.

### Adventures / Experiences

- Firestore-driven adventure activities.
- Firestore-driven featured adventure packages.
- Custom combo builder.
- Activity-specific pricing:
  - Off-road per hour per vehicle.
  - Paintball, go karts, shooting range, and extreme slide per time/person rules.
  - Camping per night/person.
- Food add-ons inside adventure reservations.
- Availability slot generation.
- Package discounts.
- Loyalty discount preview and reward reservation.
- Customer cancellation policy.

### Loyalty

- Reward wallet snapshot by national ID.
- Restaurant reward previews.
- Adventure reward previews.
- Applied reward persistence.
- Reward reservation and release.
- Profile-level reward visibility.

### Featured Posts

- Firestore-driven featured feed.
- Only visible and non-expired posts are shown.
- Pagination support.
- Restaurant, adventure, and customer categories.
- Multiple media items per post.

### Profile

- Required customer profile fields.
- Profile image upload to Firebase Storage.
- Local profile image caching.
- Profile stats.
- Theme preference.
- Social/contact links.
- Account deletion.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Local persistence | SwiftData |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| File storage | Firebase Storage |
| App state | `ObservableObject`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject` |
| Architecture | MVVM + Clean Architecture-style feature modules |
| Async | Swift Concurrency (`async` / `await`) and Firestore listeners |
| Platform | iOS |

---

## Architecture

The app follows a feature-oriented structure:

```text
root/
  feature/
    altos/
      authentication/
        data/
        domain/
        presentation/
      restaurant/
        data/
        domain/
        presentation/
      adventure/
        data/
        domain/
        presentation/
      home/
        data/
        domain/
        presentation/
      profile/
        data/
        domain/
        presentation/
  navigation/
  ui/
  util/
```

The general dependency direction is:

```text
SwiftUI View
  -> ViewModel
    -> Use Case
      -> Service / Repository Protocol
        -> Firebase / SwiftData implementation
```

### Why this structure works well

- UI code stays focused on rendering and user interaction.
- View models coordinate screen state and user actions.
- Use cases describe business operations.
- Services and repositories isolate Firebase/SwiftData details.
- Domain models remain independent from Firestore DTOs where possible.
- Feature modules can evolve separately.

---

## Main App Flow

At launch, the app configures Firebase, theme appearance, SwiftData cart storage, shared services, and root view models.

```text
AltosDelMurcoApp
  -> FirebaseApp.configure()
  -> ThemeAppearance.configure()
  -> SwiftData ModelContainer
  -> CartManager
  -> LoyaltyRewardsService
  -> OrdersService
  -> AdventureCatalogService
  -> AdventureBookingsService
  -> AuthenticationRepository
  -> ClientProfileRepository
  -> AppSessionViewModel
  -> RootView
  -> MainTabView
```

`RootView` decides what the user sees:

```text
loading
  -> SessionLoadingView

signedOut
  -> AuthenticationView

needsProfile
  -> CompleteProfileView

authenticated
  -> MainTabView

error
  -> SessionErrorView
```

---

## Feature Modules

### Authentication Module

Responsible for:

- Sign in with Apple.
- Firebase user mapping.
- Session resolution.
- Profile-gated navigation.
- Sign out.
- Account deletion.
- Firebase session validity checks.

Important types:

- `AuthenticationRepository`
- `AuthenticationRepositoriable`
- `AuthenticatedUser`
- `ClientProfile`
- `ClientProfileRepository`
- `ResolveSessionUseCase`
- `SignInWithAppleUseCase`
- `CompleteClientProfileUseCase`
- `DeleteCurrentAccountUseCase`
- `VerifyCurrentUserSessionUseCase`
- `AppSessionViewModel`
- `AuthenticationView`
- `CompleteProfileView`

### Restaurant Module

Responsible for:

- Menu loading.
- Menu categories and items.
- Cart state.
- Cart persistence.
- Checkout.
- Immediate orders.
- Scheduled food reservations.
- Order observation.
- Order status UI.
- Restaurant reward previews.

Important types:

- `MenuService`
- `OrdersService`
- `MenuViewModel`
- `OrdersViewModel`
- `CheckoutViewModel`
- `CartManager`
- `CartPersistenceService`
- `CartDraftEntity`
- `CartItemEntity`
- `OrderDto`
- `MenuItemDto`
- `RestaurantRootView`
- `MenuListView`
- `MenuItemDetailView`
- `CartView`
- `CheckoutView`
- `OrdersView`

### Adventure Module

Responsible for:

- Adventure catalog.
- Featured adventure packages.
- Custom combo builder.
- Food add-ons for reservations.
- Slot generation.
- Booking creation.
- Booking observation.
- Cancellation policy.
- Adventure reward previews.

Important types:

- `AdventureCatalogService`
- `AdventureBookingsService`
- `AdventureModuleFactory`
- `AdventurePlanner`
- `AdventurePricingEngine`
- `ExperienceComboPricingPolicy`
- `AdventureComboBuilderViewModel`
- `AdventureCatalogViewModel`
- `AdventureBookingsViewModel`
- `AdventureCatalogView`
- `ExperiencesView`
- `AdventureComboBuilderView`
- `AdventureReservationsView`
- `ReserveViewDetail`

### Home Module

Responsible for:

- Home entry points.
- Featured posts.
- Featured restaurant cards.
- Featured adventure package cards.
- Reward shortcuts.
- Navigation into exact app targets.

Important types:

- `HomeView`
- `FeaturedFeedRepository`
- `FeaturedPostModels`
- `FeaturedFeedViewModel`
- `FeaturedPostsSectionView`
- `FeaturedPostCardView`
- `FeaturedMediaCollageView`

### Profile Module

Responsible for:

- Customer profile display.
- Profile image upload/delete/cache.
- Reward wallet display.
- Customer stats.
- Theme preference.
- Account actions.

Important types:

- `ProfileContainerView`
- `ProfileImageStorageService`
- `ProfileImageCache`
- `ProfileStatsService`
- `ProfileDashboardViewModel`
- `PremiumProfileDashboard`

---

## Firebase Data Model

The app uses these Firestore collections:

| Collection | Purpose |
|---|---|
| `restaurant_menu_items` | Restaurant menu items and availability. |
| `restaurant_orders` | Immediate orders and scheduled food reservations. |
| `adventure_activities` | Configurable adventure catalog. |
| `adventure_featured_packages` | Featured experience packages and combo discounts. |
| `adventure_bookings` | Customer adventure reservations. |
| `client_loyalty_wallets` | Customer wallet/reward state. |
| `loyalty_reward_templates` | Reward rules and templates. |
| `loyalty_transactions` | Reward history/events. |
| `featured_posts` | Home featured media feed. |
| `posts` | Legacy/general post collection reference. |

### Restaurant menu item shape

Typical menu fields:

```json
{
  "id": "cuy_entero",
  "categoryId": "platos-fuertes",
  "categoryTitle": "Platos Fuertes",
  "name": "Cuy asado entero",
  "description": "Cuy asado acompañado de guarniciones.",
  "notes": null,
  "ingredients": ["Cuy", "Papas", "Ensalada"],
  "price": 24.0,
  "offerPrice": null,
  "imageURL": "https://...",
  "isAvailable": true,
  "remainingQuantity": 10,
  "isFeatured": true,
  "sortOrder": 0,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### Restaurant order shape

Typical order fields:

```json
{
  "id": "order-id",
  "clientId": "firebase-uid",
  "nationalId": "0501234567",
  "clientName": "Customer Name",
  "tableNumber": "4",
  "createdAt": "...",
  "updatedAt": "...",
  "scheduledAt": "...",
  "scheduledDayKey": "2026-04-27",
  "serviceMode": "immediate",
  "items": [],
  "subtotal": 24.0,
  "loyaltyDiscountAmount": 2.4,
  "appliedRewards": [],
  "totalAmount": 21.6,
  "status": "pending",
  "revision": 1,
  "lastConfirmedRevision": null
}
```

### Adventure activity shape

Typical activity fields:

```json
{
  "id": "offRoad",
  "title": "Off-road 4x4",
  "systemImage": "car.fill",
  "shortDescription": "Ruta de montaña en vehículo 4x4.",
  "fullDescription": "Experiencia guiada por senderos del sector.",
  "includes": ["Guía", "Equipo básico"],
  "durationOptions": [60, 120, 180],
  "pricingMode": "perHourPerVehicle",
  "basePrice": 20.0,
  "discountAmount": 0.0,
  "currency": "USD",
  "defaults": {
    "durationMinutes": 60,
    "peopleCount": 0,
    "vehicleCount": 1,
    "offRoadRiderCount": 2,
    "nights": 0
  },
  "isActive": true,
  "sortOrder": 0,
  "updatedAt": "..."
}
```

### Adventure booking shape

Typical booking fields:

```json
{
  "clientId": "firebase-uid",
  "clientName": "Customer Name",
  "whatsappNumber": "0999999999",
  "nationalId": "0501234567",
  "startDayKey": "2026-04-27",
  "startAt": "...",
  "endAt": "...",
  "guestCount": 2,
  "eventType": "regularVisit",
  "customEventTitle": null,
  "eventNotes": null,
  "items": [],
  "foodReservation": null,
  "blocks": [],
  "adventureSubtotal": 20.0,
  "foodSubtotal": 0.0,
  "subtotal": 20.0,
  "discountAmount": 0.0,
  "loyaltyDiscountAmount": 0.0,
  "appliedRewards": [],
  "nightPremium": 0.0,
  "totalAmount": 20.0,
  "status": "pending",
  "createdAt": "...",
  "notes": null
}
```

### Featured post shape

Typical featured post fields:

```json
{
  "category": "restaurant",
  "description": "Weekend special",
  "media": [
    {
      "id": "media-1",
      "downloadURL": "https://...",
      "storagePath": "featured_posts/...",
      "width": 1080,
      "height": 1350,
      "position": 0
    }
  ],
  "createdAt": "...",
  "updatedAt": "...",
  "expiresAt": "...",
  "isVisible": true
}
```

---

## Local Persistence

The iOS client uses **SwiftData** for the active restaurant cart draft.

SwiftData models:

- `CartDraftEntity`
- `CartItemEntity`

The persisted draft stores:

- Customer identity snapshot.
- National ID.
- Customer name.
- Table number.
- Scheduled date.
- Cart items.
- Item notes.
- Menu item pricing snapshot.
- Availability snapshot.
- Created/updated timestamps.

This allows the app to restore a cart after relaunch while still revalidating pricing and stock before final submission.

---

## Authentication and Profile Gate

The app uses **Sign in with Apple** and Firebase Authentication.

After authentication, the app resolves the Firebase user against a client profile document. The user cannot enter the main app until the profile is complete.

Required profile fields include:

- Full name.
- National ID.
- Phone number.
- Birthday.
- Address.
- Emergency contact name.
- Emergency contact phone.

The app validates the session:

- During bootstrap.
- When the app becomes active.
- Through a session guard task.

When Firebase reports the user as disabled, deleted, or invalid, the app closes the local session.

---

## Restaurant Ordering Flow

```text
MenuViewModel observes menu
  -> User opens item detail
    -> User adds item to cart
      -> CartManager persists draft with SwiftData
        -> CheckoutView validates customer/table/schedule
          -> OrdersService re-reads trusted menu items from Firestore
            -> LoyaltyRewardsService previews rewards
              -> Same-day order uses Firestore transaction to decrement stock
              -> Future food reservation writes order without immediate stock consumption
```

### Stock protection

For current/immediate orders, the app re-reads menu item documents and runs a Firestore transaction before writing the order. It validates:

- Item still exists.
- Item is available.
- `remainingQuantity` is enough.
- New stock value is persisted.
- `isAvailable` is updated when stock reaches zero.

---

## Adventure Reservation Flow

```text
AdventureCatalogService loads catalog + packages
  -> User selects featured package or builds custom combo
    -> AdventurePlanner creates a build plan
      -> Availability slots are generated
        -> LoyaltyRewardsService previews rewards
          -> AdventureBookingsService writes booking
            -> Loyalty rewards are reserved
```

### Supported activities

| Activity | Raw value |
|---|---|
| Off-road 4x4 | `offRoad` |
| Paintball | `paintball` |
| Go karts | `goKarts` |
| Shooting range | `shootingRange` |
| Camping | `camping` |
| Extreme slide | `extremeSlide` |

### Cancellation policy

Customers can cancel only pending or confirmed bookings before the configured cutoff. If the reservation is too close to the start time, the app asks the user to contact the business through WhatsApp.

---

## Loyalty and Rewards

The app integrates rewards into both restaurant and adventure flows.

Reward capabilities include:

- Wallet snapshot loading.
- Restaurant reward preview.
- Adventure reward preview.
- Applied reward persistence.
- Reward reservation after booking creation.
- Reward release after cancellation.
- Profile display for reward state.

Important persisted fields:

- `loyaltyDiscountAmount`
- `appliedRewards`
- `client_loyalty_wallets`
- `loyalty_reward_templates`
- `loyalty_transactions`

---

## Featured Posts

The home feed reads from `featured_posts`.

Only posts matching the following conditions are shown:

- `isVisible == true`
- `expiresAt > Date()`

The feed supports pagination through the last Firestore document snapshot.

---

## Theme and UI System

The app uses a custom premium visual system with section-aware palettes:

| Theme | Used for |
|---|---|
| `neutral` | Home, profile, bookings, shared surfaces. |
| `restaurant` | Restaurant menu, cart, checkout, orders. |
| `adventure` | Experiences, packages, adventure builder, reservations. |

Shared UI helpers include:

- `AppTheme`
- `ThemePalette`
- `ThemeAppearance`
- `BrandSectionHeader`
- `BrandIconBubble`
- `BrandBadge`
- `BrandPrimaryButtonStyle`
- `PremiumAltosComponents`
- `PremiumProfileDashboard`

---

## Project Structure

```text
Altos del Murco/
  Altos_del_MurcoApp.swift
  ContentView.swift

  root/
    feature/
      altos/
        authentication/
          data/
          domain/
          presentation/

        restaurant/
          data/
          domain/
          presentation/

        adventure/
          data/
          domain/
          presentation/

        home/
          data/
          domain/
          presentation/

        profile/
          data/
          domain/
          presentation/

    navigation/
      AppRouter.swift
      MainTabView.swift
      RootView.swift
      Route.swift

    ui/
      theme/

    util/
      constant/
      extension/
      ui/
```

---

## Setup

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd <your-repo-folder>
```

### 2. Open the project in Xcode

Open the `.xcodeproj` or `.xcworkspace` file used by this project.

```bash
open "Altos del Murco.xcodeproj"
```

If the project uses an `.xcworkspace`, open that instead.

### 3. Add Firebase configuration

Add your iOS Firebase configuration file:

```text
GoogleService-Info.plist
```

Place it in the app target and make sure it is included in **Target Membership**.

### 4. Configure Firebase services

Enable these Firebase products:

- Authentication
  - Sign in with Apple provider.
- Cloud Firestore.
- Firebase Storage.

### 5. Configure Sign in with Apple

In Apple Developer and Xcode:

- Enable **Sign in with Apple** for the app identifier.
- Add the capability in Xcode.
- Confirm bundle ID matches Firebase and Apple Developer settings.

### 6. Run the app

Select the app scheme, choose a simulator or device, then run:

```text
Cmd + R
```

---

## Firestore Indexes

Some Firestore queries may require composite indexes. Create them when Firebase shows an index error in Xcode logs.

Likely indexes include:

### Adventure bookings

```text
collection: adventure_bookings
fields:
  clientId ASC
  startAt ASC
```

### Featured posts

```text
collection: featured_posts
fields:
  isVisible ASC
  expiresAt DESC
```

### Restaurant orders

Depending on query usage:

```text
collection: restaurant_orders
fields:
  clientId ASC
  scheduledAt ASC
```

or

```text
collection: restaurant_orders
fields:
  nationalId ASC
  scheduledAt ASC
```

---

## Security Notes

Recommended Firestore and Storage rules should enforce:

- Users can only read/write their own profile.
- Users can only create orders/bookings for their authenticated UID.
- Users cannot directly modify menu, catalog, reward templates, or admin-controlled fields.
- Client-submitted prices should never be trusted without re-reading server data.
- Same-day order stock should be protected with transactions.
- Reward consumption/reservation should be validated server-side or by trusted admin/backend logic when possible.
- Profile image uploads should be restricted to the authenticated user’s own folder.
- Public featured posts should be read-only from the client app.
- Admin functionality should stay outside the customer app.

### Important production recommendation

The current client performs important validation before writes, but a production system should move critical business rules to trusted infrastructure when possible:

- Cloud Functions.
- A backend API.
- Firestore Security Rules with strict ownership checks.
- Server-side reward and pricing validation.

---

## Testing Checklist

### Authentication

- Sign in with Apple works on simulator/device.
- New users are routed to profile completion.
- Incomplete profiles cannot enter the main app.
- Existing complete profiles enter the main app.
- Disabled/deleted Firebase users are signed out after app activation.
- Account deletion reauthenticates and removes profile data.

### Restaurant

- Menu loads from Firestore.
- Categories sort correctly.
- Featured items appear on Home/Restaurant.
- Add to cart works from item detail.
- Cart survives app relaunch.
- Quantity controls respect stock.
- Immediate order decrements stock transactionally.
- Future reservation does not incorrectly consume same-day stock.
- Rewards are previewed and persisted.
- Orders appear in the bookings/orders area.

### Adventures

- Catalog loads from Firestore.
- Inactive activities are hidden.
- Featured packages load from Firestore.
- Packages with inactive activities are not shown.
- Custom combos generate valid slots.
- Food add-ons update totals.
- Loyalty rewards apply to adventure totals.
- Booking creation writes all expected fields.
- Cancellation releases reserved rewards.

### Featured posts

- Only visible, non-expired posts appear.
- Pagination loads more posts.
- Multiple media items render in order.
- Empty state appears when no posts are active.

### Profile

- Profile image uploads to Firebase Storage.
- Replacing image deletes/updates the previous path.
- Local image cache refreshes correctly.
- Reward wallet updates.
- Sign out clears authenticated state.

---

## Troubleshooting

### Firebase does not initialize

Check:

- `GoogleService-Info.plist` exists.
- It belongs to the app target.
- Bundle ID matches Firebase.
- `FirebaseApp.configure()` runs before Firebase service usage.

### Sign in with Apple fails

Check:

- Apple capability is enabled in Xcode.
- App identifier has Sign in with Apple enabled.
- Firebase Auth Apple provider is enabled.
- Bundle ID matches in Apple Developer and Firebase.

### Firestore query fails with index error

Open the Firebase console link shown in the Xcode log and create the required composite index.

### Cart does not restore

Check:

- SwiftData model container is created successfully.
- `CartDraftEntity` and `CartItemEntity` are included in the schema.
- The app is not running with in-memory storage.
- No model migration issue is blocking the store.

### Order fails during checkout

Check:

- The user is authenticated.
- Profile has national ID.
- Immediate orders include a table number.
- Menu item documents still exist.
- `remainingQuantity` is sufficient.
- Firestore rules allow the write.

### Adventure packages do not appear

Check:

- Package document has `isActive == true`.
- Package items reference valid activity raw values.
- Referenced activities are active.
- Package fields match the expected schema.

---

## Roadmap

High-value improvements for the iOS client:

- Add automated unit tests for pricing engines.
- Add ViewModel tests for checkout and adventure builder.
- Add snapshot/UI tests for critical screens.
- Add Cloud Functions or backend validation for rewards and pricing.
- Add richer analytics for customer behavior.
- Add push notifications for order/booking status changes.
- Add offline-friendly menu caching.
- Improve deep links from featured posts and promotions.
- Add structured crash/error reporting.
- Add App Store screenshots and release checklist.
- Add CI for build and test validation.

---

## Suggested Repository Files

Recommended files to keep in this repository:

```text
README.md
.gitignore
LICENSE
CONTRIBUTING.md
SECURITY.md
PRIVACY.md
CHANGELOG.md
```

Recommended `.gitignore` entries:

```gitignore
# Xcode
DerivedData/
*.xcuserstate
xcuserdata/
*.moved-aside
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods, if used
Pods/

# Firebase secrets/config
GoogleService-Info.plist

# Export/generated docs
project_swift_files.md
export_swift_to_md.sh

# macOS
.DS_Store
```

> If this repository is private and you intentionally keep `GoogleService-Info.plist` inside the repo, remove that line from `.gitignore`. For public repositories, do not commit Firebase configuration files.

---

## Contributing

Before opening a pull request:

1. Run the app locally.
2. Test sign-in and profile gating.
3. Test menu loading and checkout.
4. Test adventure package loading and booking creation.
5. Check Xcode warnings.
6. Keep Firestore schema compatibility with the Android client and ADM app.

---

## License

Add the project license here.

Example:

```text
Copyright (c) 2026 Altos del Murco.
All rights reserved.
```
