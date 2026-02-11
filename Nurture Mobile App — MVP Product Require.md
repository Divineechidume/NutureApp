# Nurture Mobile App — MVP Product Requirements Document

## Product Overview

- **Product Name:** Nurture Mobile App
- **Version:** 1.0 (MVP)
- **Platform:** iOS (initial launch), Android (future)
- **Target Users:** Parents of children ages 0–3 years who own the Nurture ankle wearable
- **Core Purpose:** A simple, calm mobile companion to the Nurture wearable that shows parents how long their child slept, when they're sleeping now, and sends safety alerts — without overwhelming them with data.

## Product Principles

- Simplicity over complexity — Show only what parents need to make decisions
- Calm, not alarming — Reassuring design and language, even for alerts
- Glanceable — Key info visible in 3 seconds or less
- No judgment — No sleep scores, grades, or optimization pressure
- Trust through reliability — Accurate tracking is more valuable than features

## User Stories

As a parent, I want to:

- See if my baby is currently asleep or awake at a glance
- Know how long my baby slept last night
- Know when my baby fell asleep and woke up
- Get notified immediately if my baby rolls over while sleeping
- Estimate when my baby might need their next nap
- Review sleep history for the past week to spot patterns
- Pair and manage my Nurture wearable device
- Feel reassured, not anxious, when checking the app

## MVP Feature Set

### 1. Device Pairing & Setup

**User Flow:**

- Open app → "Pair Your Nurture Device"
- Turn on wearable → App detects via Bluetooth
- Enter child's name, birthdate, and current age range (dropdown: 0-6mo, 6-12mo, 1-2yr, 2-3yr)
- Complete setup → Navigate to Home screen

**Requirements:**

- Bluetooth pairing with Nurture ankle wearable
- One-time device setup wizard
- Child profile creation (name, birthdate stored locally)
- Clear pairing instructions with illustrations
- Handle pairing failures gracefully with troubleshooting steps

**Edge Cases:**

- Multiple devices in range (show list to select correct one)
- Pairing timeout (retry option)
- Device already paired to another account (error message + support contact)

### 2. Home Screen — Current Status

**Primary View:**

- Large, centered status card showing:
  - Current state: "Asleep" or "Awake" (large text with icon)
  - Duration: "Sleeping for 1h 23m" or "Awake for 45m"
  - Sleep start time: "Fell asleep at 7:32 PM" (only shown when asleep)
- Secondary Info (below status card):
  - Last night's total: "9h 15m total sleep" with moon icon
  - Today's naps: "2h 30m across 2 naps" with sun icon
  - Next nap prediction: "Likely ready for a nap around 2:00 PM" (if applicable)

**Design:**

- Soft sage green background when asleep, cream when awake
- Large, readable typography (Nunito for headers)
- Minimal UI chrome — focus on the status
- Pull-to-refresh to sync latest data from wearable

**Requirements:**

- Real-time Bluetooth sync with wearable (or latest cached state)
- Auto-refresh when app comes to foreground
- Smooth state transitions (asleep ↔ awake) with gentle animation
- Offline mode: Show last known status with timestamp

### 3. Sleep History — Past 7 Days

**Navigation:** Tab or button from Home screen → "History"

**View:**

- List of past 7 days, newest first
- Each day shows:
  - Date (e.g., "Today," "Yesterday," "Monday, Feb 3")
  - Total sleep duration (nighttime + naps combined)
  - Simple bar visualization showing sleep windows
  - Tap to expand: See individual sleep sessions with start/end times

**Example Expanded Day:**

```
Wednesday, Feb 5
Total: 11h 45m

Nighttime
🌙 7:15 PM – 6:30 AM (11h 15m)

Naps
☀️ 9:45 AM – 10:15 AM (30m)
```

**Design:**

- Clean list view with subtle dividers
- Color-coded bars: nighttime (dark sage), naps (peach)
- No charts or graphs in MVP — just duration numbers
- Empty state: "No sleep data yet" with illustration

**Requirements:**

- Display sleep sessions for past 7 days
- Distinguish nighttime sleep vs. naps (based on time of day: 7 PM–7 AM = nighttime)
- Scrollable list, tappable to expand/collapse
- Data pulled from local storage (synced from wearable)

### 4. Safety Alerts — Rollover Detection

**Alert Types:**

- Critical Alert: Baby Rolled Over
- Trigger: Accelerometer detects baby has flipped from back to stomach (or vice versa) while asleep
- Notification: Push notification (even if phone is locked)
- In-app: Full-screen alert with "Check on [Child's Name]" message

**Alert Flow:**

- Wearable detects rollover → Sends signal to app via Bluetooth
- App immediately triggers push notification (sound + vibration)
- Notification message: "⚠️ [Child's Name] has rolled over"
- Tap notification → Opens app to full-screen alert:
  - "Check on [Child's Name]"
  - "They rolled over at [time]"
  - Large "I've Checked" button to dismiss
- Alert remains visible until parent dismisses

**Design:**

- Calm but urgent — use peach/coral accent color, not red
- Clear, actionable language
- Easy one-tap dismissal after checking

**Requirements:**

- Real-time Bluetooth connection for instant alerts
- Push notification permissions requested during onboarding
- Alert history log (parents can review past alerts in Settings)
- Notification sent even if app is in background or phone is locked
- Fallback: If Bluetooth disconnects, notify parent of lost connection

**Edge Cases:**

- Bluetooth disconnected: Alert parent immediately ("Connection lost with Nurture device")
- Multiple rollovers in short time: Don't spam (max 1 alert per 5 minutes unless dismissed)
- Parent already awake/active: Still send notification for awareness

### 5. Nap Prediction

**Location:** Displayed on Home screen below current status

**Logic (Simple MVP Approach):**

- Calculate average wake window for child's age:
  - 0-6 months: 1.5–2 hours
  - 6-12 months: 2–3 hours
  - 1-2 years: 4–5 hours
  - 2-3 years: 5–6 hours
- Show prediction: "Likely ready for a nap around [time]" based on when they woke up + typical wake window

**Display:**

- Only show if child is currently awake
- Update in real-time as wake duration increases
- Format: "Next nap around 2:15 PM" or "Might be ready for a nap soon"

**Requirements:**

- Age-based wake window defaults (hardcoded for MVP)
- Simple time calculation: last wake time + wake window
- Optional: Learn from child's actual patterns over time (post-MVP)

### 6. Settings & Account

**Accessible via:** Profile icon or gear icon in top-right of Home screen

**Settings Menu:**

- Child Profile: Name, Birthdate, Current age range (editable), Photo (optional)
- Device Management: Wearable battery level, Firmware version, "Unpair Device" option
- Notifications: Toggle rollover alerts on/off, Toggle nap predictions on/off
- Account: Email (for waitlist/login), Subscription status (Free vs. Premium), "Upgrade to Premium" CTA
- Support & Legal: FAQs, Contact Support, Privacy Policy, Terms of Service
- App Info: Version number, "Rate the App"

**Requirements:**

- Editable child profile
- Device battery monitoring (pulled from wearable)
- Clear unpair confirmation dialog
- Subscription management (integrate with App Store subscriptions)

### 7. Onboarding Flow

**First-Time User Experience:**

- Screen 1: Welcome — "Welcome to Nurture", illustration of wearable + phone, "Simple sleep tracking for ages 0–3", CTA: "Get Started"
- Screen 2: Permissions — Request Bluetooth and Push Notification permissions; explain why each is needed (1 sentence each)
- Screen 3: Pair Device (flow described in Feature 1)
- Screen 4: Quick Tour (Optional Carousel) — Slide 1: "See when your baby is sleeping", Slide 2: "Get alerts if they roll over", Slide 3: "Understand their sleep patterns", CTA: "Start Tracking"

**Requirements:**

- Only shown once on first app launch
- Skippable tour (not blocking)
- Smooth animations between screens

## Technical Requirements

**Platform & Frameworks:**

- iOS: Native Swift + SwiftUI (iOS 15+)
- Android (future): Native Kotlin + Jetpack Compose
- Backend (future): Firebase or similar for cloud sync (not in MVP)

**Bluetooth Requirements:**

- Bluetooth Low Energy (BLE) 5.0+
- Continuous background connection for real-time alerts
- Reconnection handling (auto-reconnect if disconnected)
- Low power consumption (optimize polling frequency)

**Data Storage:**

- Local: SQLite or Core Data for sleep history
- No cloud sync in MVP (all data stored on-device)
- Data retained for 30 days (configurable)

**Push Notifications:**

- iOS: APNs (Apple Push Notification service)
- Critical alerts enabled for rollover detection
- Customizable notification sounds

**Battery & Performance:**

- App should not drain phone battery significantly
- Optimize Bluetooth polling (check status every 5-10 seconds, not continuously)
- Efficient data sync (only pull new data, not full history)

## Out of Scope for MVP

Explicitly NOT included in v1.0:

- ❌ Sleep quality scores or analytics
- ❌ Cloud sync / multi-device support
- ❌ Social features (sharing sleep data)
- ❌ Sleep coaching or personalized advice
- ❌ Integration with other apps (Apple Health, etc.)
- ❌ Detailed charts/graphs (line charts, sleep cycles)
- ❌ Custom sleep schedules or routines
- ❌ Audio monitoring or white noise
- ❌ Video streaming (this is a wearable, not a camera)
- ❌ Multiple child profiles (one child per account in MVP)

## Success Metrics

**Primary KPIs:**

- Pairing success rate: >95% of users successfully pair device on first attempt
- Daily active users (DAU): >70% of users open app daily
- Alert reliability: 100% of rollover events trigger notification within 5 seconds
- User satisfaction: >4.5 star rating on App Store

**Secondary Metrics:**

- Average session duration: 30-60 seconds (quick glanceability)
- Retention: >80% of users still active after 30 days
- Support ticket volume: <5% of users contact support in first month

## User Experience Principles

**Visual Design:**

- Color Palette: Sage green (primary), peach/coral (alerts), lavender (accents), cream (backgrounds)
- Typography: Nunito (headings), Open Sans (body)
- Iconography: Soft, rounded icons (moon, sun, alert symbols)
- Spacing: Generous whitespace, not cluttered

**Language & Tone:**

- Reassuring, not clinical: "Your baby is sleeping peacefully" not "Subject is in sleep state"
- Actionable, not vague: "Check on Emma" not "Anomaly detected"
- Calm, not alarmist: "Emma rolled over" not "DANGER: Position change!"
- Supportive, not judgmental: "9 hours of sleep" not "Below recommended amount"

**Interaction Design:**

- One-handed use: Primary actions reachable with thumb
- Minimal taps: Key info visible without navigation
- Forgiving: Easy to undo, no destructive actions without confirmation
- Responsive: Instant feedback on all interactions

## Release Plan

**Phase 1: Private Beta (Months 1-2)**

- 50 beta families from waitlist
- iOS only
- Focus on pairing reliability and alert accuracy
- Collect feedback via in-app surveys

**Phase 2: Public Launch (Month 3)**

- iOS App Store release
- Coordinated with wearable hardware shipping
- Press and influencer outreach
- Waitlist conversion campaign

**Phase 3: Post-Launch Iteration (Months 4-6)**

- Android version development
- Feature refinements based on user feedback
- Cloud sync for multi-device support
- Apple Health integration

## Open Questions & Risks

### Technical Risks

- **Bluetooth reliability:** Can we maintain stable connection 24/7 without excessive battery drain?  
  _Mitigation:_ Extensive testing, optimize polling frequency, consider WiFi bridge as fallback
- **Sleep detection accuracy:** Will our algorithm correctly identify sleep vs. wake?  
  _Mitigation:_ Beta testing with parent-reported data, iterative model improvements
- **Alert latency:** Can we guarantee <5 second notification delivery?  
  _Mitigation:_ Direct BLE connection (no cloud), background processing permissions

### Product Questions

- **What counts as "nighttime" vs. "nap"?**  
  _Proposal:_ 7 PM – 7 AM = nighttime, rest = naps (configurable in settings later)
- **How do we handle twins or multiple children?**  
  _MVP:_ One child per account (require separate accounts for twins). _Future:_ Multi-child profiles
- **What if wearable battery dies overnight?**  
  Alert parent when battery <20%, recommend charging

## Appendix: Screen Mockup Descriptions

**Home Screen (Asleep State)**

```
[Soft sage green background]
[Top right: Settings gear icon]
[Center, large:]
😴 Asleep
Sleeping for 2h 15m
Fell asleep at 7:32 PM
[Below, cards:]
🌙 Last Night — 9h 15m total sleep
☀️ Today's Naps — 1h 30m across 1 nap
[Bottom tab bar:] Home | History | Settings
```

**Home Screen (Awake State)**

```
[Cream background]
[Center, large:]
👶 Awake
Awake for 1h 45m
[Below, cards:]
🌙 Last Night — 9h 15m total sleep
☀️ Today's Naps — 1h 30m across 1 nap
💡 Next Nap — Likely ready around 2:00 PM
[Bottom tab bar:] Home | History | Settings
```

**Rollover Alert (Full Screen)**

```
[Peach/coral background]
[Center:]
⚠️
Check on Emma
She rolled over at 9:47 PM
[Large button:] I've Checked
[Small text below:] Rollover detected 2 minutes ago
```

## Conclusion

This MVP focuses on delivering the core value proposition: simple sleep tracking with safety alerts. By limiting scope to essential features, we can ship quickly, validate with real users, and iterate based on feedback. The design prioritizes calm, glanceable information over complex analytics — staying true to Nurture's brand promise of "parenting without guesswork."
