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
  /// **'Rank by hybrid match score (OSRM)'**
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
  /// **'Hybrid ranking of preselected offers by detour, schedule and preferences. Offers retained: {count}. Offers not retained: {excluded}.'**
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

  /// No description provided for @searchHybridDetour.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min detour · {score}% match'**
  String searchHybridDetour(int minutes, int score);

  /// No description provided for @searchPreferredTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred time'**
  String get searchPreferredTime;

  /// No description provided for @searchChooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose preferred time'**
  String get searchChooseTime;

  /// No description provided for @searchRejectMatch.
  ///
  /// In en, this message translates to:
  /// **'Decline this suggestion'**
  String get searchRejectMatch;

  /// No description provided for @searchLearnedToggle.
  ///
  /// In en, this message translates to:
  /// **'Use the learned model (experimental)'**
  String get searchLearnedToggle;

  /// No description provided for @searchLearnedHelp.
  ///
  /// In en, this message translates to:
  /// **'Ranks offers with the learned model while keeping the same exclusions. The experimental score is not a real-world acceptance probability.'**
  String get searchLearnedHelp;

  /// No description provided for @searchLearnedSyntheticNotice.
  ///
  /// In en, this message translates to:
  /// **'This model was trained only on synthetic data. Its performance with real users has not been established.'**
  String get searchLearnedSyntheticNotice;

  /// No description provided for @searchLearnedLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the experimental model…'**
  String get searchLearnedLoading;

  /// No description provided for @searchLearnedFailed.
  ///
  /// In en, this message translates to:
  /// **'The experimental model is unavailable. Retry or disable this option to use the rules. No substitute ranking has been displayed.'**
  String get searchLearnedFailed;

  /// No description provided for @searchLearnedResults.
  ///
  /// In en, this message translates to:
  /// **'Experimental learned-model ranking, with the same exclusions as rule-based ranking. Offers retained: {count}. Offers not retained: {excluded}.'**
  String searchLearnedResults(int count, int excluded);

  /// No description provided for @searchLearnedScore.
  ///
  /// In en, this message translates to:
  /// **'Experimental model score: {score}/100'**
  String searchLearnedScore(String score);

  /// No description provided for @searchRuleDetour.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min detour · rule score: {score}/100'**
  String searchRuleDetour(int minutes, int score);

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get profileLanguage;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileAccountMode.
  ///
  /// In en, this message translates to:
  /// **'Account mode'**
  String get profileAccountMode;

  /// No description provided for @profileDriverMode.
  ///
  /// In en, this message translates to:
  /// **'Driver mode'**
  String get profileDriverMode;

  /// No description provided for @profileDriverEnabled.
  ///
  /// In en, this message translates to:
  /// **'Driver mode enabled'**
  String get profileDriverEnabled;

  /// No description provided for @profileDriverDisabled.
  ///
  /// In en, this message translates to:
  /// **'Driver mode disabled'**
  String get profileDriverDisabled;

  /// No description provided for @profileDriverModeDescription.
  ///
  /// In en, this message translates to:
  /// **'You can post and manage rides'**
  String get profileDriverModeDescription;

  /// No description provided for @profileEnableDriverMode.
  ///
  /// In en, this message translates to:
  /// **'Enable to post rides'**
  String get profileEnableDriverMode;

  /// No description provided for @profileQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get profileQuickActions;

  /// No description provided for @profileSearchRides.
  ///
  /// In en, this message translates to:
  /// **'Search rides'**
  String get profileSearchRides;

  /// No description provided for @profileSearchRidesDescription.
  ///
  /// In en, this message translates to:
  /// **'Find and book available rides'**
  String get profileSearchRidesDescription;

  /// No description provided for @profileMyBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get profileMyBookings;

  /// No description provided for @profileMyBookingsDescription.
  ///
  /// In en, this message translates to:
  /// **'View your ride bookings'**
  String get profileMyBookingsDescription;

  /// No description provided for @profileMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get profileMessages;

  /// No description provided for @profileMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat with drivers and passengers'**
  String get profileMessagesDescription;

  /// No description provided for @profilePostRide.
  ///
  /// In en, this message translates to:
  /// **'Post a ride'**
  String get profilePostRide;

  /// No description provided for @profilePostRideDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new ride offer'**
  String get profilePostRideDescription;

  /// No description provided for @profileManageBookings.
  ///
  /// In en, this message translates to:
  /// **'Manage bookings'**
  String get profileManageBookings;

  /// No description provided for @profileManageBookingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Accept or reject passenger bookings'**
  String get profileManageBookingsDescription;

  /// No description provided for @profileMyPostedRides.
  ///
  /// In en, this message translates to:
  /// **'My posted rides'**
  String get profileMyPostedRides;

  /// No description provided for @profileNoPostedRides.
  ///
  /// In en, this message translates to:
  /// **'No rides posted yet'**
  String get profileNoPostedRides;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'You have been logged out.'**
  String get profileLoggedOut;

  /// No description provided for @profileVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get profileVerification;

  /// No description provided for @profileNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileNotProvided;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get profileNotVerified;

  /// No description provided for @profilePendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get profilePendingReview;

  /// No description provided for @profileVerifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify now'**
  String get profileVerifyNow;

  /// No description provided for @profileFullyVerified.
  ///
  /// In en, this message translates to:
  /// **'🎉 Fully verified — you’re one of our most trusted members.'**
  String get profileFullyVerified;

  /// No description provided for @profileVerificationEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Verified members are trusted more by the community. Verification is free.'**
  String get profileVerificationEncouragement;

  /// No description provided for @profileRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} rating'**
  String profileRating(String rating);

  /// No description provided for @profileDriverBadge.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get profileDriverBadge;

  /// No description provided for @profileReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} review} other{{count} reviews}}'**
  String profileReviewCount(int count);

  /// No description provided for @profileCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} trip completed} other{{count} trips completed}}'**
  String profileCompletedTrips(int count);

  /// No description provided for @profileRideCancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get profileRideCancelledStatus;

  /// No description provided for @profileSeatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} seat available} other{{count} seats available}}'**
  String profileSeatsAvailable(int count);

  /// No description provided for @profilePricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'{price} / seat'**
  String profilePricePerSeat(String price);

  /// No description provided for @profileCancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get profileCancelRide;

  /// No description provided for @profileCancelRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this ride?'**
  String get profileCancelRideTitle;

  /// No description provided for @profileCancelRideMessage.
  ///
  /// In en, this message translates to:
  /// **'The ride from {origin} to {destination} will no longer be listed.'**
  String profileCancelRideMessage(String origin, String destination);

  /// No description provided for @profileKeepRide.
  ///
  /// In en, this message translates to:
  /// **'Keep ride'**
  String get profileKeepRide;

  /// No description provided for @profileRideCancelledNotice.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled.'**
  String get profileRideCancelledNotice;

  /// No description provided for @profileRideCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the ride. Try again.'**
  String get profileRideCancelFailed;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Try again.'**
  String get profileLoadFailed;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your profile. Try again.'**
  String get profileUpdateFailed;

  /// No description provided for @profileVerifyIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your ID?'**
  String get profileVerifyIdTitle;

  /// No description provided for @profileVerifyIdMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request will be reviewed by our support team. This helps build trust in the community.'**
  String get profileVerifyIdMessage;

  /// No description provided for @profileNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get profileNotNow;

  /// No description provided for @profileRequestVerification.
  ///
  /// In en, this message translates to:
  /// **'Request verification'**
  String get profileRequestVerification;

  /// No description provided for @profileVerificationRequested.
  ///
  /// In en, this message translates to:
  /// **'Verification requested — pending review.'**
  String get profileVerificationRequested;

  /// No description provided for @profileVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not request verification. Try again.'**
  String get profileVerificationFailed;

  /// No description provided for @profileDriverRideStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get profileDriverRideStatusAvailable;

  /// No description provided for @profileDriverRideStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get profileDriverRideStatusInProgress;

  /// No description provided for @profileDriverRideStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get profileDriverRideStatusCompleted;

  /// No description provided for @profileDriverRideStatusOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileDriverRideStatusOther;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookings;

  /// No description provided for @myBookingsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get myBookingsUpcoming;

  /// No description provided for @myBookingsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get myBookingsPast;

  /// No description provided for @myBookingsEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings'**
  String get myBookingsEmptyUpcoming;

  /// No description provided for @myBookingsEmptyPast.
  ///
  /// In en, this message translates to:
  /// **'No past bookings'**
  String get myBookingsEmptyPast;

  /// No description provided for @myBookingsBrowseRides.
  ///
  /// In en, this message translates to:
  /// **'Browse available rides and book one!'**
  String get myBookingsBrowseRides;

  /// No description provided for @myBookingsHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Your ride history will appear here.'**
  String get myBookingsHistoryHint;

  /// No description provided for @myBookingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your bookings. Try again.'**
  String get myBookingsLoadFailed;

  /// No description provided for @myBookingsCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get myBookingsCancelTitle;

  /// No description provided for @myBookingsCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get myBookingsCancelConfirm;

  /// No description provided for @myBookingsKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get myBookingsKeep;

  /// No description provided for @myBookingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get myBookingsCancel;

  /// No description provided for @myBookingsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled.'**
  String get myBookingsCancelled;

  /// No description provided for @myBookingsCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the booking. Try again.'**
  String get myBookingsCancelFailed;

  /// No description provided for @myBookingsRateDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate {driver}'**
  String myBookingsRateDriver(String driver);

  /// No description provided for @myBookingsCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get myBookingsCommentOptional;

  /// No description provided for @myBookingsTripFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'How was the trip?'**
  String get myBookingsTripFeedbackHint;

  /// No description provided for @myBookingsSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get myBookingsSubmit;

  /// No description provided for @myBookingsReviewThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review.'**
  String get myBookingsReviewThanks;

  /// No description provided for @myBookingsReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your review. Try again.'**
  String get myBookingsReviewFailed;

  /// No description provided for @myBookingsChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the conversation. Try again.'**
  String get myBookingsChatFailed;

  /// No description provided for @myBookingsStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get myBookingsStart;

  /// No description provided for @myBookingsEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get myBookingsEnd;

  /// No description provided for @myBookingsDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departs: {date} at {time}'**
  String myBookingsDeparture(String date, String time);

  /// No description provided for @myBookingsDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get myBookingsDriver;

  /// No description provided for @myBookingsDriverRating.
  ///
  /// In en, this message translates to:
  /// **'{driver} ({rating} ⭐)'**
  String myBookingsDriverRating(String driver, String rating);

  /// No description provided for @myBookingsYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get myBookingsYourBooking;

  /// No description provided for @myBookingsSeatsAndTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} seat} other{{count} seats}} · {price}'**
  String myBookingsSeatsAndTotal(int count, String price);

  /// No description provided for @myBookingsPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {location}'**
  String myBookingsPickup(String location);

  /// No description provided for @myBookingsAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver to approve your booking'**
  String get myBookingsAwaitingApproval;

  /// No description provided for @myBookingsLiveTrack.
  ///
  /// In en, this message translates to:
  /// **'Live safety tracking'**
  String get myBookingsLiveTrack;

  /// No description provided for @myBookingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get myBookingsMessage;

  /// No description provided for @myBookingsRateAction.
  ///
  /// In en, this message translates to:
  /// **'Rate driver'**
  String get myBookingsRateAction;

  /// No description provided for @myBookingsConfirmedStatus.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get myBookingsConfirmedStatus;

  /// No description provided for @myBookingsPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get myBookingsPendingStatus;

  /// No description provided for @myBookingsCompletedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get myBookingsCompletedStatus;

  /// No description provided for @myBookingsCancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get myBookingsCancelledStatus;

  /// No description provided for @myBookingsRejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get myBookingsRejectedStatus;

  /// No description provided for @myBookingsOtherStatus.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get myBookingsOtherStatus;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your language selection. Please try again.'**
  String get languageSaveFailed;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get editProfilePersonalInfo;

  /// No description provided for @editProfileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get editProfileFirstName;

  /// No description provided for @editProfileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get editProfileLastName;

  /// No description provided for @editProfilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editProfilePhone;

  /// No description provided for @editProfileBio.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get editProfileBio;

  /// No description provided for @editProfileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell passengers a bit about yourself'**
  String get editProfileBioHint;

  /// No description provided for @editProfileContactMethod.
  ///
  /// In en, this message translates to:
  /// **'Preferred contact method'**
  String get editProfileContactMethod;

  /// No description provided for @editProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileEmail;

  /// No description provided for @editProfilePhoneContact.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editProfilePhoneContact;

  /// No description provided for @editProfileInAppChat.
  ///
  /// In en, this message translates to:
  /// **'In-app chat'**
  String get editProfileInAppChat;

  /// No description provided for @editProfileVehicle.
  ///
  /// In en, this message translates to:
  /// **'My vehicle'**
  String get editProfileVehicle;

  /// No description provided for @editProfileVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Used to pre-fill your ride postings and shown to passengers.'**
  String get editProfileVehicleHint;

  /// No description provided for @editProfileMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get editProfileMake;

  /// No description provided for @editProfileMakeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toyota'**
  String get editProfileMakeHint;

  /// No description provided for @editProfileModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get editProfileModel;

  /// No description provided for @editProfileModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Corolla'**
  String get editProfileModelHint;

  /// No description provided for @editProfileColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get editProfileColor;

  /// No description provided for @editProfileColorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. White'**
  String get editProfileColorHint;

  /// No description provided for @editProfileYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get editProfileYear;

  /// No description provided for @editProfileYearHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2022'**
  String get editProfileYearHint;

  /// No description provided for @editProfilePlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get editProfilePlate;

  /// No description provided for @editProfilePlateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC 123'**
  String get editProfilePlateHint;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editProfileSave;

  /// No description provided for @editProfileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editProfileSaving;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get editProfileSaved;

  /// No description provided for @editProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get editProfileSaveFailed;

  /// No description provided for @chatMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatMessagesTitle;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get chatRefresh;

  /// No description provided for @chatRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get chatRetry;

  /// No description provided for @chatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load conversations. Please try again.'**
  String get chatLoadFailed;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the message. Please try again.'**
  String get chatSendFailed;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Message a driver from a ride or a passenger from your bookings to start chatting.'**
  String get chatEmptyMessage;

  /// No description provided for @chatMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get chatMember;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessages;

  /// No description provided for @chatNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get chatNow;

  /// No description provided for @chatMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String chatMinutesAgo(int minutes);

  /// No description provided for @chatHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String chatHoursAgo(int hours);

  /// No description provided for @chatDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String chatDaysAgo(int days);

  /// No description provided for @chatThreadEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatThreadEmptyTitle;

  /// No description provided for @chatThreadEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Say hi and confirm the details of your trip.'**
  String get chatThreadEmptyMessage;

  /// No description provided for @chatPassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get chatPassenger;

  /// No description provided for @chatBookingRequest.
  ///
  /// In en, this message translates to:
  /// **'{passenger} requested {count, plural, one{one seat} other{{count} seats}} for {price}'**
  String chatBookingRequest(String passenger, int count, String price);

  /// No description provided for @chatDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get chatDecline;

  /// No description provided for @chatAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get chatAccept;

  /// No description provided for @chatWriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get chatWriteMessage;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @driverBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage bookings'**
  String get driverBookingsTitle;

  /// No description provided for @driverBookingsNoRidesTitle.
  ///
  /// In en, this message translates to:
  /// **'No rides posted yet'**
  String get driverBookingsNoRidesTitle;

  /// No description provided for @driverBookingsNoRidesMessage.
  ///
  /// In en, this message translates to:
  /// **'Post a ride to start receiving booking requests.'**
  String get driverBookingsNoRidesMessage;

  /// No description provided for @driverBookingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load rides and bookings. Please try again.'**
  String get driverBookingsLoadFailed;

  /// No description provided for @driverBookingsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'That action failed. Check your connection and try again.'**
  String get driverBookingsActionFailed;

  /// No description provided for @driverBookingsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking accepted.'**
  String get driverBookingsAccepted;

  /// No description provided for @driverBookingsRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected.'**
  String get driverBookingsRejected;

  /// No description provided for @driverBookingsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled.'**
  String get driverBookingsCancelled;

  /// No description provided for @driverBookingsRideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Ride marked as completed.'**
  String get driverBookingsRideCompleted;

  /// No description provided for @driverBookingsDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departs: {date} at {time}'**
  String driverBookingsDeparture(String date, String time);

  /// No description provided for @driverBookingsSeatsPrice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} seat} other{{count} seats}} · {price}'**
  String driverBookingsSeatsPrice(int count, String price);

  /// No description provided for @driverBookingsNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get driverBookingsNoBookings;

  /// No description provided for @driverBookingsLiveTrack.
  ///
  /// In en, this message translates to:
  /// **'Live safety tracking'**
  String get driverBookingsLiveTrack;

  /// No description provided for @driverBookingsCompleteRide.
  ///
  /// In en, this message translates to:
  /// **'Mark ride as completed'**
  String get driverBookingsCompleteRide;

  /// No description provided for @driverBookingsPassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get driverBookingsPassenger;

  /// No description provided for @driverBookingsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String driverBookingsPhone(String phone);

  /// No description provided for @driverBookingsPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {location}'**
  String driverBookingsPickup(String location);

  /// No description provided for @driverBookingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get driverBookingsMessage;

  /// No description provided for @driverBookingsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get driverBookingsReject;

  /// No description provided for @driverBookingsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get driverBookingsAccept;

  /// No description provided for @driverBookingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get driverBookingsCancel;

  /// No description provided for @safetyShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share my live trip'**
  String get safetyShareButton;

  /// No description provided for @safetyConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing consent'**
  String get safetyConsentTitle;

  /// No description provided for @safetyConsentMessage.
  ///
  /// In en, this message translates to:
  /// **'Québec Law 25: your precise GPS location will be shared with anyone who has this link until it expires (3 hours) or you stop sharing. The link does not require an account. You may withdraw consent at any time by stopping tracking.'**
  String get safetyConsentMessage;

  /// No description provided for @safetyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get safetyCancel;

  /// No description provided for @safetyStartSharing.
  ///
  /// In en, this message translates to:
  /// **'I agree and share'**
  String get safetyStartSharing;

  /// No description provided for @safetyStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get safetyStopSharing;

  /// No description provided for @safetySharingStarted.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is active.'**
  String get safetySharingStarted;

  /// No description provided for @safetySharingStopped.
  ///
  /// In en, this message translates to:
  /// **'Location sharing has stopped.'**
  String get safetySharingStopped;

  /// No description provided for @safetyShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start location sharing. Check permissions and try again.'**
  String get safetyShareFailed;

  /// No description provided for @safetyRideNotActive.
  ///
  /// In en, this message translates to:
  /// **'Tracking is available while the ride is in progress.'**
  String get safetyRideNotActive;

  /// No description provided for @safetyTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety tracking and sharing'**
  String get safetyTrackingTitle;

  /// No description provided for @safetyTrackingStart.
  ///
  /// In en, this message translates to:
  /// **'Safety tracking & sharing'**
  String get safetyTrackingStart;

  /// No description provided for @safetyTrackingParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count} participant(s) on the map'**
  String safetyTrackingParticipants(int count);

  /// No description provided for @safetyTrackingVisibleBy.
  ///
  /// In en, this message translates to:
  /// **'Your position is visible to ride participants and anyone with your tracking link (expires in 3 hours).'**
  String get safetyTrackingVisibleBy;

  /// No description provided for @safetyTrackingNotSharing.
  ///
  /// In en, this message translates to:
  /// **'Your position is not being shared.'**
  String get safetyTrackingNotSharing;

  /// No description provided for @safetyTrackingSharing.
  ///
  /// In en, this message translates to:
  /// **'Your position is being shared live.'**
  String get safetyTrackingSharing;

  /// No description provided for @safetyTrackingCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get safetyTrackingCopyLink;

  /// No description provided for @safetyTrackingSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send to a contact'**
  String get safetyTrackingSendLink;

  /// No description provided for @safetyTrackingLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Tracking link copied.'**
  String get safetyTrackingLinkCopied;

  /// No description provided for @safetyTrackingRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter on my position'**
  String get safetyTrackingRecenter;

  /// No description provided for @safetyTrackingStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get safetyTrackingStartLabel;

  /// No description provided for @safetyTrackingEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get safetyTrackingEndLabel;

  /// No description provided for @safetyTrackingMyPosition.
  ///
  /// In en, this message translates to:
  /// **'My position'**
  String get safetyTrackingMyPosition;

  /// No description provided for @safetyTrackingParticipant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get safetyTrackingParticipant;

  /// No description provided for @safetyTrackingLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Check location permissions.'**
  String get safetyTrackingLocationUnavailable;
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
