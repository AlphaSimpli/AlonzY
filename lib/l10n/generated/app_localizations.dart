import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a ride'**
  String get postTitle;

  /// No description provided for @postRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Where is your route?'**
  String get postRouteTitle;

  /// No description provided for @postScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'When are you departing?'**
  String get postScheduleTitle;

  /// No description provided for @postPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Seats, price & vehicle'**
  String get postPriceTitle;

  /// No description provided for @postPoliciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip policies'**
  String get postPoliciesTitle;

  /// No description provided for @postRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get postRoute;

  /// No description provided for @postSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get postSchedule;

  /// No description provided for @postPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get postPricing;

  /// No description provided for @postPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get postPolicies;

  /// No description provided for @postPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get postPickup;

  /// No description provided for @postPickupHint.
  ///
  /// In en, this message translates to:
  /// **'Where are you leaving from?'**
  String get postPickupHint;

  /// No description provided for @postDropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get postDropoff;

  /// No description provided for @postDropoffHint.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get postDropoffHint;

  /// No description provided for @postMapHint.
  ///
  /// In en, this message translates to:
  /// **'Select both locations to preview the route on the map.'**
  String get postMapHint;

  /// No description provided for @postInvalidLocations.
  ///
  /// In en, this message translates to:
  /// **'Select locations with a recognized municipality from the suggestions.'**
  String get postInvalidLocations;

  /// No description provided for @postInvalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price per seat greater than zero.'**
  String get postInvalidPrice;

  /// No description provided for @postPickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a departure time'**
  String get postPickTime;

  /// No description provided for @postDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get postDeparture;

  /// No description provided for @postTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get postTime;

  /// No description provided for @postSeatsPricing.
  ///
  /// In en, this message translates to:
  /// **'Seats & pricing'**
  String get postSeatsPricing;

  /// No description provided for @postPricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'Price per seat (CAD)'**
  String get postPricePerSeat;

  /// No description provided for @postPriceHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get postPriceHint;

  /// No description provided for @postMake.
  ///
  /// In en, this message translates to:
  /// **'Make (optional)'**
  String get postMake;

  /// No description provided for @postMakeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toyota'**
  String get postMakeHint;

  /// No description provided for @postModel.
  ///
  /// In en, this message translates to:
  /// **'Model (optional)'**
  String get postModel;

  /// No description provided for @postModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Corolla'**
  String get postModelHint;

  /// No description provided for @postColor.
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get postColor;

  /// No description provided for @postColorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. White'**
  String get postColorHint;

  /// No description provided for @postYear.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get postYear;

  /// No description provided for @postYearHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2022'**
  String get postYearHint;

  /// No description provided for @postPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate (optional)'**
  String get postPlate;

  /// No description provided for @postPlateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC 123'**
  String get postPlateHint;

  /// No description provided for @postRidePolicies.
  ///
  /// In en, this message translates to:
  /// **'Ride policies'**
  String get postRidePolicies;

  /// No description provided for @postInstantBooking.
  ///
  /// In en, this message translates to:
  /// **'Instant booking'**
  String get postInstantBooking;

  /// No description provided for @postInstantExplanation.
  ///
  /// In en, this message translates to:
  /// **'Passengers book immediately. Turn off to review and approve each booking request first.'**
  String get postInstantExplanation;

  /// No description provided for @postPetsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Pets allowed'**
  String get postPetsAllowed;

  /// No description provided for @postPetsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Allow passengers to bring well-behaved pets.'**
  String get postPetsExplanation;

  /// No description provided for @postLuggageSpace.
  ///
  /// In en, this message translates to:
  /// **'Luggage space'**
  String get postLuggageSpace;

  /// No description provided for @postLuggageNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get postLuggageNone;

  /// No description provided for @postLuggageSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get postLuggageSmall;

  /// No description provided for @postLuggageStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get postLuggageStandard;

  /// No description provided for @postLuggageLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get postLuggageLarge;

  /// No description provided for @postNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes for passengers (optional)'**
  String get postNotes;

  /// No description provided for @postNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. music, luggage, stops along the way'**
  String get postNotesHint;

  /// No description provided for @postSummaryBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking: {policy}'**
  String postSummaryBooking(String policy);

  /// No description provided for @postSummaryPets.
  ///
  /// In en, this message translates to:
  /// **'Pets: {policy}'**
  String postSummaryPets(String policy);

  /// No description provided for @postSummaryLuggage.
  ///
  /// In en, this message translates to:
  /// **'Luggage: {policy}'**
  String postSummaryLuggage(String policy);

  /// No description provided for @postSummaryNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String postSummaryNotes(String notes);

  /// No description provided for @postBookingInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get postBookingInstant;

  /// No description provided for @postBookingApproval.
  ///
  /// In en, this message translates to:
  /// **'Driver approval'**
  String get postBookingApproval;

  /// No description provided for @postReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to publish'**
  String get postReady;

  /// No description provided for @postBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get postBack;

  /// No description provided for @postContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get postContinue;

  /// No description provided for @postPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish ride'**
  String get postPublish;

  /// No description provided for @postPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get postPublishing;

  /// No description provided for @postPublished.
  ///
  /// In en, this message translates to:
  /// **'Ride published!'**
  String get postPublished;

  /// No description provided for @postPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Passengers can now find your ride in search and book according to your booking settings.'**
  String get postPublishedMessage;

  /// No description provided for @postGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get postGreat;

  /// No description provided for @postFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not post your ride. Check your connection and sign-in, then try again.'**
  String get postFailed;

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride details'**
  String get detailsTitle;

  /// No description provided for @detailsDateTime.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String detailsDateTime(String date, String time);

  /// No description provided for @detailsRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} rating'**
  String detailsRating(String rating);

  /// No description provided for @detailsCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 trips completed} one{1 trip completed} other{{count} trips completed}}'**
  String detailsCompletedTrips(int count);

  /// No description provided for @detailsVehicleHeading.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & trip details'**
  String get detailsVehicleHeading;

  /// No description provided for @detailsVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get detailsVehicle;

  /// No description provided for @detailsVehicleUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not specified'**
  String get detailsVehicleUnspecified;

  /// No description provided for @detailsSedan.
  ///
  /// In en, this message translates to:
  /// **'Sedan'**
  String get detailsSedan;

  /// No description provided for @detailsSuv.
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get detailsSuv;

  /// No description provided for @detailsVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get detailsVan;

  /// No description provided for @detailsPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get detailsPets;

  /// No description provided for @detailsPetsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get detailsPetsAllowed;

  /// No description provided for @detailsPetsNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get detailsPetsNotAllowed;

  /// No description provided for @detailsLuggage.
  ///
  /// In en, this message translates to:
  /// **'Luggage'**
  String get detailsLuggage;

  /// No description provided for @detailsLuggageNone.
  ///
  /// In en, this message translates to:
  /// **'No luggage space'**
  String get detailsLuggageNone;

  /// No description provided for @detailsLuggageSmall.
  ///
  /// In en, this message translates to:
  /// **'Small bags only'**
  String get detailsLuggageSmall;

  /// No description provided for @detailsLuggageStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard luggage'**
  String get detailsLuggageStandard;

  /// No description provided for @detailsLuggageLarge.
  ///
  /// In en, this message translates to:
  /// **'Large items welcome'**
  String get detailsLuggageLarge;

  /// No description provided for @detailsBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get detailsBooking;

  /// No description provided for @detailsInstantBooking.
  ///
  /// In en, this message translates to:
  /// **'Instant: confirmed immediately'**
  String get detailsInstantBooking;

  /// No description provided for @detailsApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Driver approval required'**
  String get detailsApprovalRequired;

  /// No description provided for @detailsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get detailsNotes;

  /// No description provided for @detailsPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get detailsPrice;

  /// No description provided for @detailsPricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'{price} / seat'**
  String detailsPricePerSeat(String price);

  /// No description provided for @detailsSeatsToBook.
  ///
  /// In en, this message translates to:
  /// **'Seats to book'**
  String get detailsSeatsToBook;

  /// No description provided for @detailsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get detailsTotal;

  /// No description provided for @detailsMessageDriver.
  ///
  /// In en, this message translates to:
  /// **'Message driver'**
  String get detailsMessageDriver;

  /// No description provided for @detailsBookingLoading.
  ///
  /// In en, this message translates to:
  /// **'Booking…'**
  String get detailsBookingLoading;

  /// No description provided for @detailsBookSeats.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Book 1 seat} other{Book {count} seats}}'**
  String detailsBookSeats(int count);

  /// No description provided for @detailsSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Only 1 seat left} other{Only {count} seats left}}'**
  String detailsSeatsLeft(int count);

  /// No description provided for @detailsBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get detailsBookingConfirmed;

  /// No description provided for @detailsBookingRequested.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent: awaiting driver approval'**
  String get detailsBookingRequested;

  /// No description provided for @detailsAlreadyBooked.
  ///
  /// In en, this message translates to:
  /// **'You already have an active booking for this ride.'**
  String get detailsAlreadyBooked;

  /// No description provided for @detailsNotEnoughSeats.
  ///
  /// In en, this message translates to:
  /// **'Not enough seats left on this ride.'**
  String get detailsNotEnoughSeats;

  /// No description provided for @detailsBookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking failed. Check your connection and try again.'**
  String get detailsBookingFailed;

  /// No description provided for @detailsChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open chat. Check your connection and try again.'**
  String get detailsChatFailed;

  /// No description provided for @verificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get verificationEmail;

  /// No description provided for @verificationPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get verificationPhone;

  /// No description provided for @verificationGovernmentId.
  ///
  /// In en, this message translates to:
  /// **'Government ID'**
  String get verificationGovernmentId;

  /// No description provided for @verificationVerified.
  ///
  /// In en, this message translates to:
  /// **'{label}: verified'**
  String verificationVerified(String label);

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'{label}: pending'**
  String verificationPending(String label);

  /// No description provided for @verificationUnverified.
  ///
  /// In en, this message translates to:
  /// **'{label}: not verified'**
  String verificationUnverified(String label);

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Rides'**
  String get searchTitle;

  /// No description provided for @searchHeading.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get searchHeading;

  /// No description provided for @searchIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Tell us your trip and we\'ll find a ride for you.'**
  String get searchIntroduction;

  /// No description provided for @searchFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get searchFrom;

  /// No description provided for @searchFromHint.
  ///
  /// In en, this message translates to:
  /// **'Leaving from…'**
  String get searchFromHint;

  /// No description provided for @searchTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get searchTo;

  /// No description provided for @searchToHint.
  ///
  /// In en, this message translates to:
  /// **'Going to…'**
  String get searchToHint;

  /// No description provided for @searchSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap pickup and drop-off'**
  String get searchSwap;

  /// No description provided for @searchPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a departure date'**
  String get searchPickDate;

  /// No description provided for @searchDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get searchDate;

  /// No description provided for @searchAnyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get searchAnyDate;

  /// No description provided for @searchSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get searchSeats;

  /// No description provided for @searchFewerSeats.
  ///
  /// In en, this message translates to:
  /// **'Fewer seats'**
  String get searchFewerSeats;

  /// No description provided for @searchMoreSeats.
  ///
  /// In en, this message translates to:
  /// **'More seats'**
  String get searchMoreSeats;

  /// No description provided for @searchMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price per seat (optional)'**
  String get searchMaxPrice;

  /// No description provided for @searchInvalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid, non-negative maximum price.'**
  String get searchInvalidPrice;

  /// No description provided for @searchNearbyHint.
  ///
  /// In en, this message translates to:
  /// **'Nearby search: departures within 10 km. Destination is still matched by text.'**
  String get searchNearbyHint;

  /// No description provided for @searchTextHint.
  ///
  /// In en, this message translates to:
  /// **'Text search. Select a departure suggestion and a date to search departures within 10 km.'**
  String get searchTextHint;

  /// No description provided for @searchSubmit.
  ///
  /// In en, this message translates to:
  /// **'Search rides'**
  String get searchSubmit;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searchLoading;

  /// No description provided for @searchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable'**
  String get searchUnavailable;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection and sign-in, then try again.'**
  String get searchFailed;

  /// No description provided for @searchTooMany.
  ///
  /// In en, this message translates to:
  /// **'More than 100 nearby offers. Narrow the date, price or seat filters.'**
  String get searchTooMany;

  /// No description provided for @searchInitialTitle.
  ///
  /// In en, this message translates to:
  /// **'Search for a ride'**
  String get searchInitialTitle;

  /// No description provided for @searchInitialMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your trip details above and tap \"Search rides\" to see available trips.'**
  String get searchInitialMessage;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rides found'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search filters'**
  String get searchEmptyMessage;

  /// No description provided for @searchUnknownCity.
  ///
  /// In en, this message translates to:
  /// **'Unknown city'**
  String get searchUnknownCity;

  /// No description provided for @searchDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get searchDriver;

  /// No description provided for @searchDriverInitial.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get searchDriverInitial;

  /// No description provided for @searchAvailableSeats.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 seats} one{1 seat} other{{count} seats}}'**
  String searchAvailableSeats(int count);

  /// No description provided for @searchDeparted.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get searchDeparted;

  /// No description provided for @searchDepartsHours.
  ///
  /// In en, this message translates to:
  /// **'Departs in {hours}h {minutes}m'**
  String searchDepartsHours(int hours, int minutes);

  /// No description provided for @searchDepartsMinutes.
  ///
  /// In en, this message translates to:
  /// **'Departs in {minutes}m'**
  String searchDepartsMinutes(int minutes);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get navPost;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navBookingsShort.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookingsShort;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Drive & earn'**
  String get homeDriveTitle;

  /// No description provided for @homeDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post a ride and fill your empty seats.'**
  String get homeDriveSubtitle;

  /// No description provided for @homePostRide.
  ///
  /// In en, this message translates to:
  /// **'Post a ride'**
  String get homePostRide;

  /// No description provided for @homeFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a ride'**
  String get homeFindTitle;

  /// No description provided for @homeFindSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search available rides near you and book instantly.'**
  String get homeFindSubtitle;

  /// No description provided for @homeSearchRides.
  ///
  /// In en, this message translates to:
  /// **'Search rides'**
  String get homeSearchRides;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find or share your next ride.'**
  String get loginSubtitle;

  /// No description provided for @newToAlonzy.
  ///
  /// In en, this message translates to:
  /// **'New to Alonzy?'**
  String get newToAlonzy;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @phoneTab.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneTab;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @enterEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password'**
  String get enterEmailAndPassword;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterReceivedCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code you received'**
  String get enterReceivedCode;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +15145550123'**
  String get phoneNumberHint;

  /// No description provided for @phoneCodeExplanation.
  ///
  /// In en, this message translates to:
  /// **'We\'ll text you a one-time code to sign in.'**
  String get phoneCodeExplanation;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @verificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCodeLabel;

  /// No description provided for @verificationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get verificationCodeHint;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @verifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & sign in'**
  String get verifyAndSignIn;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It takes less than a minute to get started.'**
  String get signupSubtitle;

  /// No description provided for @signupTermsNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our terms and privacy policy.'**
  String get signupTermsNotice;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @optionalPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get optionalPhoneLabel;

  /// No description provided for @passwordLengthHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordLengthHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signupValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email and a password of at least 6 characters'**
  String get signupValidation;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to verify before signing in.'**
  String get accountCreated;

  /// No description provided for @authIncorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get authIncorrectCredentials;

  /// No description provided for @authAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists'**
  String get authAccountExists;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before signing in'**
  String get authEmailNotConfirmed;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email address.'**
  String get authInvalidEmail;

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Check your phone number, including the country code.'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is invalid or has expired. Request a new code.'**
  String get authInvalidCode;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment before trying again.'**
  String get authRateLimited;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get authWeakPassword;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Check your connection and try again.'**
  String get authLoginFailed;

  /// No description provided for @authSignupFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create your account. Check your connection and try again.'**
  String get authSignupFailed;

  /// No description provided for @authSendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the code. Check your connection and try again.'**
  String get authSendCodeFailed;

  /// No description provided for @authVerifyCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify the code. Try again or request a new code.'**
  String get authVerifyCodeFailed;

  /// No description provided for @searchRoadToggle.
  ///
  /// In en, this message translates to:
  /// **'Rank by road detour (OSRM)'**
  String get searchRoadToggle;

  /// No description provided for @searchRoadNearbyHint.
  ///
  /// In en, this message translates to:
  /// **'PostGIS preselection: departures within 10 km of your pickup. The destination is evaluated by OSRM.'**
  String get searchRoadNearbyHint;

  /// No description provided for @searchRoadHelp.
  ///
  /// In en, this message translates to:
  /// **'Select both suggested addresses and a date. Passenger and offer coordinates are sent to the public OSRM server and may be logged. Prototype: at most {limit} preselected offers and {km} km of additional detour. Estimates do not include live traffic.'**
  String searchRoadHelp(int limit, int km);

  /// No description provided for @searchRoadRequired.
  ///
  /// In en, this message translates to:
  /// **'For OSRM, select pickup and destination from the suggestions, then choose a date.'**
  String get searchRoadRequired;

  /// No description provided for @searchRoadTooMany.
  ///
  /// In en, this message translates to:
  /// **'More than {limit} preselected offers. Narrow the search (date, price or seats), or disable OSRM. No partial road ranking is displayed.'**
  String searchRoadTooMany(int limit);

  /// No description provided for @searchRoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Road routing is unavailable. Retry or disable OSRM to use normal search. No substitute ranking has been displayed.'**
  String get searchRoadFailed;

  /// No description provided for @searchRoadLoading.
  ///
  /// In en, this message translates to:
  /// **'Calculating OSRM detours…'**
  String get searchRoadLoading;

  /// No description provided for @searchRoadResults.
  ///
  /// In en, this message translates to:
  /// **'OSRM ranking by additional detour among preselected offers. Offers retained: {count}. Offers not retained: {excluded}.'**
  String searchRoadResults(int count, int excluded);

  /// No description provided for @searchRoadEmpty.
  ///
  /// In en, this message translates to:
  /// **'No preselected offer meets the 15 km detour limit, or no usable road route was found.'**
  String get searchRoadEmpty;

  /// No description provided for @searchRoadDetour.
  ///
  /// In en, this message translates to:
  /// **'Estimated driver detour (OSRM): +{km} km · +{minutes} min'**
  String searchRoadDetour(String km, int minutes);

  /// No description provided for @searchRoadAttribution.
  ///
  /// In en, this message translates to:
  /// **'Routes: OSRM. Data: © OpenStreetMap contributors (ODbL).\nhttps://project-osrm.org/\nhttps://www.openstreetmap.org/copyright\nFix the map: https://www.openstreetmap.org/fixthemap'**
  String get searchRoadAttribution;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
