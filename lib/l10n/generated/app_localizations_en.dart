// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get postTitle => 'Post a ride';

  @override
  String get postRouteTitle => 'Where is your route?';

  @override
  String get postScheduleTitle => 'When are you departing?';

  @override
  String get postPriceTitle => 'Seats, price & vehicle';

  @override
  String get postPoliciesTitle => 'Trip policies';

  @override
  String get postRoute => 'Route';

  @override
  String get postSchedule => 'Schedule';

  @override
  String get postPricing => 'Pricing';

  @override
  String get postPolicies => 'Policies';

  @override
  String get postPickup => 'Pickup';

  @override
  String get postPickupHint => 'Where are you leaving from?';

  @override
  String get postDropoff => 'Drop-off';

  @override
  String get postDropoffHint => 'Where are you going?';

  @override
  String get postMapHint =>
      'Select both locations to preview the route on the map.';

  @override
  String get postInvalidLocations =>
      'Select locations with a recognized municipality from the suggestions.';

  @override
  String get postInvalidPrice =>
      'Enter a valid price per seat greater than zero.';

  @override
  String get postPickTime => 'Pick a departure time';

  @override
  String get postDeparture => 'Departure';

  @override
  String get postTime => 'Time';

  @override
  String get postSeatsPricing => 'Seats & pricing';

  @override
  String get postPricePerSeat => 'Price per seat (CAD)';

  @override
  String get postPriceHint => '0.00';

  @override
  String get postMake => 'Make (optional)';

  @override
  String get postMakeHint => 'e.g. Toyota';

  @override
  String get postModel => 'Model (optional)';

  @override
  String get postModelHint => 'e.g. Corolla';

  @override
  String get postColor => 'Color (optional)';

  @override
  String get postColorHint => 'e.g. White';

  @override
  String get postYear => 'Year (optional)';

  @override
  String get postYearHint => 'e.g. 2022';

  @override
  String get postPlate => 'Plate (optional)';

  @override
  String get postPlateHint => 'e.g. ABC 123';

  @override
  String get postRidePolicies => 'Ride policies';

  @override
  String get postInstantBooking => 'Instant booking';

  @override
  String get postInstantExplanation =>
      'Passengers book immediately. Turn off to review and approve each booking request first.';

  @override
  String get postPetsAllowed => 'Pets allowed';

  @override
  String get postPetsExplanation =>
      'Allow passengers to bring well-behaved pets.';

  @override
  String get postLuggageSpace => 'Luggage space';

  @override
  String get postLuggageNone => 'None';

  @override
  String get postLuggageSmall => 'Small';

  @override
  String get postLuggageStandard => 'Standard';

  @override
  String get postLuggageLarge => 'Large';

  @override
  String get postNotes => 'Notes for passengers (optional)';

  @override
  String get postNotesHint => 'e.g. music, luggage, stops along the way';

  @override
  String postSummaryBooking(String policy) {
    return 'Booking: $policy';
  }

  @override
  String postSummaryPets(String policy) {
    return 'Pets: $policy';
  }

  @override
  String postSummaryLuggage(String policy) {
    return 'Luggage: $policy';
  }

  @override
  String postSummaryNotes(String notes) {
    return 'Notes: $notes';
  }

  @override
  String get postBookingInstant => 'Instant';

  @override
  String get postBookingApproval => 'Driver approval';

  @override
  String get postReady => 'Ready to publish';

  @override
  String get postBack => 'Back';

  @override
  String get postContinue => 'Continue';

  @override
  String get postPublish => 'Publish ride';

  @override
  String get postPublishing => 'Publishing…';

  @override
  String get postPublished => 'Ride published!';

  @override
  String get postPublishedMessage =>
      'Passengers can now find your ride in search and book according to your booking settings.';

  @override
  String get postGreat => 'Great';

  @override
  String get postFailed =>
      'Could not post your ride. Check your connection and sign-in, then try again.';

  @override
  String get detailsTitle => 'Ride details';

  @override
  String detailsDateTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String detailsRating(String rating) {
    return '$rating rating';
  }

  @override
  String detailsCompletedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips completed',
      one: '1 trip completed',
      zero: '0 trips completed',
    );
    return '$_temp0';
  }

  @override
  String get detailsVehicleHeading => 'Vehicle & trip details';

  @override
  String get detailsVehicle => 'Vehicle';

  @override
  String get detailsVehicleUnspecified => 'Vehicle not specified';

  @override
  String get detailsSedan => 'Sedan';

  @override
  String get detailsSuv => 'SUV';

  @override
  String get detailsVan => 'Van';

  @override
  String get detailsPets => 'Pets';

  @override
  String get detailsPetsAllowed => 'Allowed';

  @override
  String get detailsPetsNotAllowed => 'Not allowed';

  @override
  String get detailsLuggage => 'Luggage';

  @override
  String get detailsLuggageNone => 'No luggage space';

  @override
  String get detailsLuggageSmall => 'Small bags only';

  @override
  String get detailsLuggageStandard => 'Standard luggage';

  @override
  String get detailsLuggageLarge => 'Large items welcome';

  @override
  String get detailsBooking => 'Booking';

  @override
  String get detailsInstantBooking => 'Instant: confirmed immediately';

  @override
  String get detailsApprovalRequired => 'Driver approval required';

  @override
  String get detailsNotes => 'Notes';

  @override
  String get detailsPrice => 'Price';

  @override
  String detailsPricePerSeat(String price) {
    return '$price / seat';
  }

  @override
  String get detailsSeatsToBook => 'Seats to book';

  @override
  String get detailsTotal => 'Total';

  @override
  String get detailsMessageDriver => 'Message driver';

  @override
  String get detailsBookingLoading => 'Booking…';

  @override
  String detailsBookSeats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Book $count seats',
      one: 'Book 1 seat',
    );
    return '$_temp0';
  }

  @override
  String detailsSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count seats left',
      one: 'Only 1 seat left',
    );
    return '$_temp0';
  }

  @override
  String get detailsBookingConfirmed => 'Booking confirmed';

  @override
  String get detailsBookingRequested =>
      'Booking request sent: awaiting driver approval';

  @override
  String get detailsAlreadyBooked =>
      'You already have an active booking for this ride.';

  @override
  String get detailsNotEnoughSeats => 'Not enough seats left on this ride.';

  @override
  String get detailsBookingFailed =>
      'Booking failed. Check your connection and try again.';

  @override
  String get detailsChatFailed =>
      'Could not open chat. Check your connection and try again.';

  @override
  String get verificationEmail => 'Email';

  @override
  String get verificationPhone => 'Phone';

  @override
  String get verificationGovernmentId => 'Government ID';

  @override
  String verificationVerified(String label) {
    return '$label: verified';
  }

  @override
  String verificationPending(String label) {
    return '$label: pending';
  }

  @override
  String verificationUnverified(String label) {
    return '$label: not verified';
  }

  @override
  String get searchTitle => 'Find Rides';

  @override
  String get searchHeading => 'Where are you going?';

  @override
  String get searchIntroduction =>
      'Tell us your trip and we\'ll find a ride for you.';

  @override
  String get searchFrom => 'From';

  @override
  String get searchFromHint => 'Leaving from…';

  @override
  String get searchTo => 'To';

  @override
  String get searchToHint => 'Going to…';

  @override
  String get searchSwap => 'Swap pickup and drop-off';

  @override
  String get searchPickDate => 'Pick a departure date';

  @override
  String get searchDate => 'Date';

  @override
  String get searchAnyDate => 'Any date';

  @override
  String get searchSeats => 'Seats';

  @override
  String get searchFewerSeats => 'Fewer seats';

  @override
  String get searchMoreSeats => 'More seats';

  @override
  String get searchMaxPrice => 'Max price per seat (optional)';

  @override
  String get searchInvalidPrice => 'Enter a valid, non-negative maximum price.';

  @override
  String get searchNearbyHint =>
      'Nearby search: departures within 10 km. Destination is still matched by text.';

  @override
  String get searchTextHint =>
      'Text search. Select a departure suggestion and a date to search departures within 10 km.';

  @override
  String get searchSubmit => 'Search rides';

  @override
  String get searchLoading => 'Searching…';

  @override
  String get searchUnavailable => 'Search unavailable';

  @override
  String get searchFailed =>
      'Search failed. Check your connection and sign-in, then try again.';

  @override
  String get searchTooMany =>
      'More than 100 nearby offers. Narrow the date, price or seat filters.';

  @override
  String get searchInitialTitle => 'Search for a ride';

  @override
  String get searchInitialMessage =>
      'Enter your trip details above and tap \"Search rides\" to see available trips.';

  @override
  String get searchEmptyTitle => 'No rides found';

  @override
  String get searchEmptyMessage => 'Try adjusting your search filters';

  @override
  String get searchUnknownCity => 'Unknown city';

  @override
  String get searchDriver => 'Driver';

  @override
  String get searchDriverInitial => 'D';

  @override
  String searchAvailableSeats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '1 seat',
      zero: '0 seats',
    );
    return '$_temp0';
  }

  @override
  String get searchDeparted => 'Departed';

  @override
  String searchDepartsHours(int hours, int minutes) {
    return 'Departs in ${hours}h ${minutes}m';
  }

  @override
  String searchDepartsMinutes(int minutes) {
    return 'Departs in ${minutes}m';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navPost => 'Post';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navBookingsShort => 'Bookings';

  @override
  String get navChat => 'Chat';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeDriveTitle => 'Drive & earn';

  @override
  String get homeDriveSubtitle => 'Post a ride and fill your empty seats.';

  @override
  String get homePostRide => 'Post a ride';

  @override
  String get homeFindTitle => 'Find a ride';

  @override
  String get homeFindSubtitle =>
      'Search available rides near you and book instantly.';

  @override
  String get homeSearchRides => 'Search rides';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to find or share your next ride.';

  @override
  String get newToAlonzy => 'New to Alonzy?';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneTab => 'Phone';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signIn => 'Sign in';

  @override
  String get enterEmailAndPassword => 'Enter your email and password';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get enterReceivedCode => 'Enter the code you received';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => 'e.g. +15145550123';

  @override
  String get phoneCodeExplanation =>
      'We\'ll text you a one-time code to sign in.';

  @override
  String get sendCode => 'Send code';

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get verificationCodeHint => '6-digit code';

  @override
  String get changePhoneNumber => 'Change phone number';

  @override
  String get verifyAndSignIn => 'Verify & sign in';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get signupSubtitle => 'It takes less than a minute to get started.';

  @override
  String get signupTermsNotice =>
      'By continuing you agree to our terms and privacy policy.';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get optionalPhoneLabel => 'Phone (optional)';

  @override
  String get passwordLengthHint => 'At least 6 characters';

  @override
  String get createAccount => 'Create account';

  @override
  String get signupValidation =>
      'Enter a valid email and a password of at least 6 characters';

  @override
  String get accountCreated =>
      'Account created. Check your email to verify before signing in.';

  @override
  String get authIncorrectCredentials => 'Incorrect email or password';

  @override
  String get authAccountExists => 'An account with this email already exists';

  @override
  String get authEmailNotConfirmed =>
      'Please verify your email before signing in';

  @override
  String get authInvalidEmail => 'Check your email address.';

  @override
  String get authInvalidPhone =>
      'Check your phone number, including the country code.';

  @override
  String get authInvalidCode =>
      'The code is invalid or has expired. Request a new code.';

  @override
  String get authRateLimited =>
      'Too many attempts. Wait a moment before trying again.';

  @override
  String get authWeakPassword => 'Choose a stronger password.';

  @override
  String get authLoginFailed =>
      'Unable to sign in. Check your connection and try again.';

  @override
  String get authSignupFailed =>
      'Unable to create your account. Check your connection and try again.';

  @override
  String get authSendCodeFailed =>
      'Unable to send the code. Check your connection and try again.';

  @override
  String get authVerifyCodeFailed =>
      'Unable to verify the code. Try again or request a new code.';

  @override
  String get searchRoadToggle => 'Rank by hybrid match score (OSRM)';

  @override
  String get searchRoadNearbyHint =>
      'PostGIS preselection: departures within 10 km of your pickup. The destination is evaluated by OSRM.';

  @override
  String searchRoadHelp(int limit, int km) {
    return 'Select both suggested addresses and a date. Passenger and offer coordinates are sent to the public OSRM server and may be logged. Prototype: at most $limit preselected offers and $km km of additional detour. Estimates do not include live traffic.';
  }

  @override
  String get searchRoadRequired =>
      'For OSRM, select pickup and destination from the suggestions, then choose a date.';

  @override
  String searchRoadTooMany(int limit) {
    return 'More than $limit preselected offers. Narrow the search (date, price or seats), or disable OSRM. No partial road ranking is displayed.';
  }

  @override
  String get searchRoadFailed =>
      'Road routing is unavailable. Retry or disable OSRM to use normal search. No substitute ranking has been displayed.';

  @override
  String get searchRoadLoading => 'Calculating OSRM detours…';

  @override
  String searchRoadResults(int count, int excluded) {
    return 'Hybrid ranking of preselected offers by detour, schedule and preferences. Offers retained: $count. Offers not retained: $excluded.';
  }

  @override
  String get searchRoadEmpty =>
      'No preselected offer meets the 15 km detour limit, or no usable road route was found.';

  @override
  String searchRoadDetour(String km, int minutes) {
    return 'Estimated driver detour (OSRM): +$km km · +$minutes min';
  }

  @override
  String get searchRoadAttribution =>
      'Routes: OSRM. Data: © OpenStreetMap contributors (ODbL).\nhttps://project-osrm.org/\nhttps://www.openstreetmap.org/copyright\nFix the map: https://www.openstreetmap.org/fixthemap';

  @override
  String searchHybridDetour(int minutes, int score) {
    return '$minutes min detour · $score% match';
  }

  @override
  String get searchPreferredTime => 'Preferred time';

  @override
  String get searchChooseTime => 'Choose preferred time';

  @override
  String get searchRejectMatch => 'Decline this suggestion';

  @override
  String get profileSettingsTitle => 'Profile & Settings';

  @override
  String get profileLanguage => 'App language';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileAccountMode => 'Account mode';

  @override
  String get profileDriverMode => 'Driver mode';

  @override
  String get profileDriverEnabled => 'Driver mode enabled';

  @override
  String get profileDriverDisabled => 'Driver mode disabled';

  @override
  String get profileDriverModeDescription => 'You can post and manage rides';

  @override
  String get profileEnableDriverMode => 'Enable to post rides';

  @override
  String get profileQuickActions => 'Quick actions';

  @override
  String get profileSearchRides => 'Search rides';

  @override
  String get profileSearchRidesDescription => 'Find and book available rides';

  @override
  String get profileMyBookings => 'My bookings';

  @override
  String get profileMyBookingsDescription => 'View your ride bookings';

  @override
  String get profileMessages => 'Messages';

  @override
  String get profileMessagesDescription => 'Chat with drivers and passengers';

  @override
  String get profilePostRide => 'Post a ride';

  @override
  String get profilePostRideDescription => 'Create a new ride offer';

  @override
  String get profileManageBookings => 'Manage bookings';

  @override
  String get profileManageBookingsDescription =>
      'Accept or reject passenger bookings';

  @override
  String get profileMyPostedRides => 'My posted rides';

  @override
  String get profileNoPostedRides => 'No rides posted yet';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLoggedOut => 'You have been logged out.';

  @override
  String get profileVerification => 'Verification';

  @override
  String get profileNotProvided => 'Not provided';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileNotVerified => 'Not verified';

  @override
  String get profilePendingReview => 'Pending review';

  @override
  String get profileVerifyNow => 'Verify now';

  @override
  String get profileFullyVerified =>
      '🎉 Fully verified — you’re one of our most trusted members.';

  @override
  String get profileVerificationEncouragement =>
      'Verified members are trusted more by the community. Verification is free.';

  @override
  String profileRating(String rating) {
    return '$rating rating';
  }

  @override
  String get profileDriverBadge => 'Driver';

  @override
  String profileReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '$count review',
    );
    return '$_temp0';
  }

  @override
  String profileCompletedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips completed',
      one: '$count trip completed',
    );
    return '$_temp0';
  }

  @override
  String get profileRideCancelledStatus => 'Cancelled';

  @override
  String profileSeatsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats available',
      one: '$count seat available',
    );
    return '$_temp0';
  }

  @override
  String profilePricePerSeat(String price) {
    return '$price / seat';
  }

  @override
  String get profileCancelRide => 'Cancel ride';

  @override
  String get profileCancelRideTitle => 'Cancel this ride?';

  @override
  String profileCancelRideMessage(String origin, String destination) {
    return 'The ride from $origin to $destination will no longer be listed.';
  }

  @override
  String get profileKeepRide => 'Keep ride';

  @override
  String get profileRideCancelledNotice => 'Ride cancelled.';

  @override
  String get profileRideCancelFailed => 'Could not cancel the ride. Try again.';

  @override
  String get profileLoadFailed => 'Could not load your profile. Try again.';

  @override
  String get profileUpdateFailed => 'Could not update your profile. Try again.';

  @override
  String get profileVerifyIdTitle => 'Verify your ID?';

  @override
  String get profileVerifyIdMessage =>
      'Your request will be reviewed by our support team. This helps build trust in the community.';

  @override
  String get profileNotNow => 'Not now';

  @override
  String get profileRequestVerification => 'Request verification';

  @override
  String get profileVerificationRequested =>
      'Verification requested — pending review.';

  @override
  String get profileVerificationFailed =>
      'Could not request verification. Try again.';

  @override
  String get profileDriverRideStatusAvailable => 'Available';

  @override
  String get profileDriverRideStatusInProgress => 'In progress';

  @override
  String get profileDriverRideStatusCompleted => 'Completed';

  @override
  String get profileDriverRideStatusOther => 'Other';

  @override
  String get myBookings => 'My bookings';

  @override
  String get myBookingsUpcoming => 'Upcoming';

  @override
  String get myBookingsPast => 'Past';

  @override
  String get myBookingsEmptyUpcoming => 'No upcoming bookings';

  @override
  String get myBookingsEmptyPast => 'No past bookings';

  @override
  String get myBookingsBrowseRides => 'Browse available rides and book one!';

  @override
  String get myBookingsHistoryHint => 'Your ride history will appear here.';

  @override
  String get myBookingsLoadFailed => 'Could not load your bookings. Try again.';

  @override
  String get myBookingsCancelTitle => 'Cancel booking?';

  @override
  String get myBookingsCancelConfirm =>
      'Are you sure you want to cancel this booking?';

  @override
  String get myBookingsKeep => 'Keep booking';

  @override
  String get myBookingsCancel => 'Cancel booking';

  @override
  String get myBookingsCancelled => 'Booking cancelled.';

  @override
  String get myBookingsCancelFailed =>
      'Could not cancel the booking. Try again.';

  @override
  String myBookingsRateDriver(String driver) {
    return 'Rate $driver';
  }

  @override
  String get myBookingsCommentOptional => 'Comment (optional)';

  @override
  String get myBookingsTripFeedbackHint => 'How was the trip?';

  @override
  String get myBookingsSubmit => 'Submit';

  @override
  String get myBookingsReviewThanks => 'Thank you for your review.';

  @override
  String get myBookingsReviewFailed =>
      'Could not submit your review. Try again.';

  @override
  String get myBookingsChatFailed =>
      'Could not open the conversation. Try again.';

  @override
  String get myBookingsStart => 'Start';

  @override
  String get myBookingsEnd => 'End';

  @override
  String myBookingsDeparture(String date, String time) {
    return 'Departs: $date at $time';
  }

  @override
  String get myBookingsDriver => 'Driver';

  @override
  String myBookingsDriverRating(String driver, String rating) {
    return '$driver ($rating ⭐)';
  }

  @override
  String get myBookingsYourBooking => 'Your booking';

  @override
  String myBookingsSeatsAndTotal(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '$count seat',
    );
    return '$_temp0 · $price';
  }

  @override
  String myBookingsPickup(String location) {
    return 'Pickup: $location';
  }

  @override
  String get myBookingsAwaitingApproval =>
      'Waiting for the driver to approve your booking';

  @override
  String get myBookingsLiveTrack => 'Live safety tracking';

  @override
  String get myBookingsMessage => 'Message';

  @override
  String get myBookingsRateAction => 'Rate driver';

  @override
  String get myBookingsConfirmedStatus => 'Confirmed';

  @override
  String get myBookingsPendingStatus => 'Pending';

  @override
  String get myBookingsCompletedStatus => 'Completed';

  @override
  String get myBookingsCancelledStatus => 'Cancelled';

  @override
  String get myBookingsRejectedStatus => 'Rejected';

  @override
  String get myBookingsOtherStatus => 'Other';

  @override
  String get languageSaveFailed =>
      'Could not save your language selection. Please try again.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfilePersonalInfo => 'Personal information';

  @override
  String get editProfileFirstName => 'First name';

  @override
  String get editProfileLastName => 'Last name';

  @override
  String get editProfilePhone => 'Phone';

  @override
  String get editProfileBio => 'About me';

  @override
  String get editProfileBioHint => 'Tell passengers a bit about yourself';

  @override
  String get editProfileContactMethod => 'Preferred contact method';

  @override
  String get editProfileEmail => 'Email';

  @override
  String get editProfilePhoneContact => 'Phone';

  @override
  String get editProfileInAppChat => 'In-app chat';

  @override
  String get editProfileVehicle => 'My vehicle';

  @override
  String get editProfileVehicleHint =>
      'Used to pre-fill your ride postings and shown to passengers.';

  @override
  String get editProfileMake => 'Make';

  @override
  String get editProfileMakeHint => 'e.g. Toyota';

  @override
  String get editProfileModel => 'Model';

  @override
  String get editProfileModelHint => 'e.g. Corolla';

  @override
  String get editProfileColor => 'Color';

  @override
  String get editProfileColorHint => 'e.g. White';

  @override
  String get editProfileYear => 'Year';

  @override
  String get editProfileYearHint => 'e.g. 2022';

  @override
  String get editProfilePlate => 'Plate';

  @override
  String get editProfilePlateHint => 'e.g. ABC 123';

  @override
  String get editProfileSave => 'Save changes';

  @override
  String get editProfileSaving => 'Saving…';

  @override
  String get editProfileSaved => 'Profile updated.';

  @override
  String get editProfileSaveFailed =>
      'Could not save your profile. Please try again.';

  @override
  String get chatMessagesTitle => 'Messages';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatRefresh => 'Refresh';

  @override
  String get chatRetry => 'Try again';

  @override
  String get chatLoadFailed =>
      'Could not load conversations. Please try again.';

  @override
  String get chatSendFailed => 'Could not send the message. Please try again.';

  @override
  String get chatEmptyTitle => 'No conversations yet';

  @override
  String get chatEmptyMessage =>
      'Message a driver from a ride or a passenger from your bookings to start chatting.';

  @override
  String get chatMember => 'Member';

  @override
  String get chatNoMessages => 'No messages yet';

  @override
  String get chatNow => 'now';

  @override
  String chatMinutesAgo(int minutes) {
    return '${minutes}m';
  }

  @override
  String chatHoursAgo(int hours) {
    return '${hours}h';
  }

  @override
  String chatDaysAgo(int days) {
    return '${days}d';
  }

  @override
  String get chatThreadEmptyTitle => 'No messages yet';

  @override
  String get chatThreadEmptyMessage =>
      'Say hi and confirm the details of your trip.';

  @override
  String get chatPassenger => 'Passenger';

  @override
  String chatBookingRequest(String passenger, int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: 'one seat',
    );
    return '$passenger requested $_temp0 for $price';
  }

  @override
  String get chatDecline => 'Decline';

  @override
  String get chatAccept => 'Accept';

  @override
  String get chatWriteMessage => 'Write a message…';

  @override
  String get chatSend => 'Send';

  @override
  String get driverBookingsTitle => 'Manage bookings';

  @override
  String get driverBookingsNoRidesTitle => 'No rides posted yet';

  @override
  String get driverBookingsNoRidesMessage =>
      'Post a ride to start receiving booking requests.';

  @override
  String get driverBookingsLoadFailed =>
      'Could not load rides and bookings. Please try again.';

  @override
  String get driverBookingsActionFailed =>
      'That action failed. Check your connection and try again.';

  @override
  String get driverBookingsAccepted => 'Booking accepted.';

  @override
  String get driverBookingsRejected => 'Booking rejected.';

  @override
  String get driverBookingsCancelled => 'Booking cancelled.';

  @override
  String get driverBookingsRideCompleted => 'Ride marked as completed.';

  @override
  String driverBookingsDeparture(String date, String time) {
    return 'Departs: $date at $time';
  }

  @override
  String driverBookingsSeatsPrice(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '$count seat',
    );
    return '$_temp0 · $price';
  }

  @override
  String get driverBookingsNoBookings => 'No bookings yet';

  @override
  String get driverBookingsLiveTrack => 'Live safety tracking';

  @override
  String get driverBookingsCompleteRide => 'Mark ride as completed';

  @override
  String get driverBookingsPassenger => 'Passenger';

  @override
  String driverBookingsPhone(String phone) {
    return 'Phone: $phone';
  }

  @override
  String driverBookingsPickup(String location) {
    return 'Pickup: $location';
  }

  @override
  String get driverBookingsMessage => 'Message';

  @override
  String get driverBookingsReject => 'Reject';

  @override
  String get driverBookingsAccept => 'Accept';

  @override
  String get driverBookingsCancel => 'Cancel';

  @override
  String get safetyShareButton => 'Share my live trip';

  @override
  String get safetyConsentTitle => 'Sharing consent';

  @override
  String get safetyConsentMessage =>
      'Québec Law 25: your precise GPS location will be shared with anyone who has this link until it expires (3 hours) or you stop sharing. The link does not require an account. You may withdraw consent at any time by stopping tracking.';

  @override
  String get safetyCancel => 'Cancel';

  @override
  String get safetyStartSharing => 'I agree and share';

  @override
  String get safetyStopSharing => 'Stop sharing';

  @override
  String get safetySharingStarted => 'Location sharing is active.';

  @override
  String get safetySharingStopped => 'Location sharing has stopped.';

  @override
  String get safetyShareFailed =>
      'Could not start location sharing. Check permissions and try again.';

  @override
  String get safetyRideNotActive =>
      'Tracking is available while the ride is in progress.';

  @override
  String get safetyTrackingTitle => 'Safety tracking and sharing';

  @override
  String get safetyTrackingStart => 'Safety tracking & sharing';

  @override
  String safetyTrackingParticipants(int count) {
    return '$count participant(s) on the map';
  }

  @override
  String get safetyTrackingVisibleBy =>
      'Your position is visible to ride participants and anyone with your tracking link (expires in 3 hours).';

  @override
  String get safetyTrackingNotSharing => 'Your position is not being shared.';

  @override
  String get safetyTrackingSharing => 'Your position is being shared live.';

  @override
  String get safetyTrackingCopyLink => 'Copy link';

  @override
  String get safetyTrackingSendLink => 'Send to a contact';

  @override
  String get safetyTrackingLinkCopied => 'Tracking link copied.';

  @override
  String get safetyTrackingRecenter => 'Recenter on my position';

  @override
  String get safetyTrackingStartLabel => 'Start';

  @override
  String get safetyTrackingEndLabel => 'Destination';

  @override
  String get safetyTrackingMyPosition => 'My position';

  @override
  String get safetyTrackingParticipant => 'Participant';

  @override
  String get safetyTrackingLocationUnavailable =>
      'Could not get your location. Check location permissions.';
}
