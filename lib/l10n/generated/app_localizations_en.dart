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
  String get searchRoadToggle => 'Rank by road detour (OSRM)';

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
    return 'OSRM ranking by additional detour among preselected offers. Offers retained: $count. Offers not retained: $excluded.';
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
}
