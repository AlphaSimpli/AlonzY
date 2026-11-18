// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get postTitle => 'Publier un trajet';

  @override
  String get postRouteTitle => 'Quel est votre parcours ?';

  @override
  String get postScheduleTitle => 'Quand partez-vous ?';

  @override
  String get postPriceTitle => 'Places, prix et véhicule';

  @override
  String get postPoliciesTitle => 'Conditions du trajet';

  @override
  String get postRoute => 'Parcours';

  @override
  String get postSchedule => 'Horaire';

  @override
  String get postPricing => 'Tarif';

  @override
  String get postPolicies => 'Options';

  @override
  String get postPickup => 'Départ';

  @override
  String get postPickupHint => 'D’où partez-vous ?';

  @override
  String get postDropoff => 'Destination';

  @override
  String get postDropoffHint => 'Où allez-vous ?';

  @override
  String get postMapHint =>
      'Choisissez les deux adresses pour afficher l’aperçu du parcours sur la carte.';

  @override
  String get postInvalidLocations =>
      'Choisissez dans les suggestions des adresses associées à une municipalité reconnue.';

  @override
  String get postInvalidPrice =>
      'Saisissez un prix par place valide, strictement supérieur à zéro.';

  @override
  String get postPickTime => 'Choisir une heure de départ';

  @override
  String get postDeparture => 'Départ';

  @override
  String get postTime => 'Heure';

  @override
  String get postSeatsPricing => 'Places et tarif';

  @override
  String get postPricePerSeat => 'Prix par place (CAD)';

  @override
  String get postPriceHint => '0,00';

  @override
  String get postMake => 'Marque (facultatif)';

  @override
  String get postMakeHint => 'Ex. : Toyota';

  @override
  String get postModel => 'Modèle (facultatif)';

  @override
  String get postModelHint => 'Ex. : Corolla';

  @override
  String get postColor => 'Couleur (facultatif)';

  @override
  String get postColorHint => 'Ex. : Blanc';

  @override
  String get postYear => 'Année (facultatif)';

  @override
  String get postYearHint => 'Ex. : 2022';

  @override
  String get postPlate => 'Plaque (facultatif)';

  @override
  String get postPlateHint => 'Ex. : ABC 123';

  @override
  String get postRidePolicies => 'Conditions de voyage';

  @override
  String get postInstantBooking => 'Réservation instantanée';

  @override
  String get postInstantExplanation =>
      'Les passagers réservent immédiatement. Désactivez cette option pour examiner et approuver chaque demande au préalable.';

  @override
  String get postPetsAllowed => 'Animaux autorisés';

  @override
  String get postPetsExplanation =>
      'Autoriser les passagers à voyager avec des animaux bien élevés.';

  @override
  String get postLuggageSpace => 'Espace pour les bagages';

  @override
  String get postLuggageNone => 'Aucun';

  @override
  String get postLuggageSmall => 'Petit';

  @override
  String get postLuggageStandard => 'Standard';

  @override
  String get postLuggageLarge => 'Grand';

  @override
  String get postNotes => 'Notes pour les passagers (facultatif)';

  @override
  String get postNotesHint => 'Ex. : musique, bagages, arrêts en chemin';

  @override
  String postSummaryBooking(String policy) {
    return 'Réservation : $policy';
  }

  @override
  String postSummaryPets(String policy) {
    return 'Animaux : $policy';
  }

  @override
  String postSummaryLuggage(String policy) {
    return 'Bagages : $policy';
  }

  @override
  String postSummaryNotes(String notes) {
    return 'Notes : $notes';
  }

  @override
  String get postBookingInstant => 'Instantanée';

  @override
  String get postBookingApproval => 'Approbation du conducteur';

  @override
  String get postReady => 'Prêt à publier';

  @override
  String get postBack => 'Retour';

  @override
  String get postContinue => 'Continuer';

  @override
  String get postPublish => 'Publier le trajet';

  @override
  String get postPublishing => 'Publication en cours…';

  @override
  String get postPublished => 'Trajet publié !';

  @override
  String get postPublishedMessage =>
      'Les passagers peuvent maintenant trouver votre trajet dans la recherche et réserver selon vos paramètres de réservation.';

  @override
  String get postGreat => 'Très bien';

  @override
  String get postFailed =>
      'Impossible de publier votre trajet. Vérifiez votre connexion Internet et votre connexion au compte, puis réessayez.';

  @override
  String get detailsTitle => 'Détails du trajet';

  @override
  String detailsDateTime(String date, String time) {
    return '$date à $time';
  }

  @override
  String detailsRating(String rating) {
    return 'Note : $rating';
  }

  @override
  String detailsCompletedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trajets effectués',
      one: '1 trajet effectué',
      zero: '0 trajet effectué',
    );
    return '$_temp0';
  }

  @override
  String get detailsVehicleHeading => 'Véhicule et détails du trajet';

  @override
  String get detailsVehicle => 'Véhicule';

  @override
  String get detailsVehicleUnspecified => 'Véhicule non précisé';

  @override
  String get detailsSedan => 'Berline';

  @override
  String get detailsSuv => 'VUS';

  @override
  String get detailsVan => 'Fourgonnette';

  @override
  String get detailsPets => 'Animaux';

  @override
  String get detailsPetsAllowed => 'Autorisés';

  @override
  String get detailsPetsNotAllowed => 'Non autorisés';

  @override
  String get detailsLuggage => 'Bagages';

  @override
  String get detailsLuggageNone => 'Aucun espace pour les bagages';

  @override
  String get detailsLuggageSmall => 'Petits sacs uniquement';

  @override
  String get detailsLuggageStandard => 'Bagages standards';

  @override
  String get detailsLuggageLarge => 'Bagages volumineux acceptés';

  @override
  String get detailsBooking => 'Réservation';

  @override
  String get detailsInstantBooking => 'Instantanée : confirmation immédiate';

  @override
  String get detailsApprovalRequired => 'Approbation du conducteur requise';

  @override
  String get detailsNotes => 'Notes';

  @override
  String get detailsPrice => 'Prix';

  @override
  String detailsPricePerSeat(String price) {
    return '$price / place';
  }

  @override
  String get detailsSeatsToBook => 'Places à réserver';

  @override
  String get detailsTotal => 'Total';

  @override
  String get detailsMessageDriver => 'Contacter le conducteur';

  @override
  String get detailsBookingLoading => 'Réservation en cours…';

  @override
  String detailsBookSeats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Réserver $count places',
      one: 'Réserver 1 place',
    );
    return '$_temp0';
  }

  @override
  String detailsSeatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il ne reste que $count places',
      one: 'Il ne reste qu’une place',
    );
    return '$_temp0';
  }

  @override
  String get detailsBookingConfirmed => 'Réservation confirmée';

  @override
  String get detailsBookingRequested =>
      'Demande de réservation envoyée : en attente de l’approbation du conducteur';

  @override
  String get detailsAlreadyBooked =>
      'Vous avez déjà une réservation active pour ce trajet.';

  @override
  String get detailsNotEnoughSeats =>
      'Il ne reste pas assez de places pour ce trajet.';

  @override
  String get detailsBookingFailed =>
      'La réservation a échoué. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get detailsChatFailed =>
      'Impossible d’ouvrir la conversation. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get verificationEmail => 'Courriel';

  @override
  String get verificationPhone => 'Téléphone';

  @override
  String get verificationGovernmentId => 'Pièce d’identité';

  @override
  String verificationVerified(String label) {
    return '$label : vérification effectuée';
  }

  @override
  String verificationPending(String label) {
    return '$label : vérification en attente';
  }

  @override
  String verificationUnverified(String label) {
    return '$label : vérification non effectuée';
  }

  @override
  String get searchTitle => 'Rechercher un trajet';

  @override
  String get searchHeading => 'Où allez-vous ?';

  @override
  String get searchIntroduction =>
      'Indiquez votre parcours pour trouver un trajet.';

  @override
  String get searchFrom => 'Départ';

  @override
  String get searchFromHint => 'Adresse de départ…';

  @override
  String get searchTo => 'Destination';

  @override
  String get searchToHint => 'Adresse d’arrivée…';

  @override
  String get searchSwap => 'Inverser le départ et la destination';

  @override
  String get searchPickDate => 'Choisir une date de départ';

  @override
  String get searchDate => 'Date';

  @override
  String get searchAnyDate => 'Toutes les dates';

  @override
  String get searchSeats => 'Places';

  @override
  String get searchFewerSeats => 'Moins de places';

  @override
  String get searchMoreSeats => 'Plus de places';

  @override
  String get searchMaxPrice => 'Prix maximal par place (facultatif)';

  @override
  String get searchInvalidPrice =>
      'Saisissez un prix maximal valide, supérieur ou égal à zéro.';

  @override
  String get searchNearbyHint =>
      'Recherche à proximité : départs dans un rayon de 10 km. La destination reste filtrée par texte.';

  @override
  String get searchTextHint =>
      'Recherche textuelle. Choisissez une suggestion de départ et une date pour rechercher les départs dans un rayon de 10 km.';

  @override
  String get searchSubmit => 'Rechercher';

  @override
  String get searchLoading => 'Recherche en cours…';

  @override
  String get searchUnavailable => 'Recherche indisponible';

  @override
  String get searchFailed =>
      'La recherche a échoué. Vérifiez votre connexion Internet et votre connexion au compte, puis réessayez.';

  @override
  String get searchTooMany =>
      'Plus de 100 offres à proximité. Précisez les filtres de date, de prix ou de places.';

  @override
  String get searchInitialTitle => 'Trouvez un trajet';

  @override
  String get searchInitialMessage =>
      'Indiquez les détails de votre parcours, puis appuyez sur « Rechercher » pour voir les trajets disponibles.';

  @override
  String get searchEmptyTitle => 'Aucun trajet trouvé';

  @override
  String get searchEmptyMessage =>
      'Essayez de modifier vos filtres de recherche.';

  @override
  String get searchUnknownCity => 'Ville inconnue';

  @override
  String get searchDriver => 'Conducteur';

  @override
  String get searchDriverInitial => 'C';

  @override
  String searchAvailableSeats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
      zero: '0 place',
    );
    return '$_temp0';
  }

  @override
  String get searchDeparted => 'Départ passé';

  @override
  String searchDepartsHours(int hours, int minutes) {
    return 'Départ dans $hours h $minutes min';
  }

  @override
  String searchDepartsMinutes(int minutes) {
    return 'Départ dans $minutes min';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navPost => 'Publier';

  @override
  String get navBookings => 'Réservations';

  @override
  String get navBookingsShort => 'Réserv.';

  @override
  String get navChat => 'Messages';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeDriveTitle => 'Conduisez et gagnez';

  @override
  String get homeDriveSubtitle =>
      'Publiez un trajet et remplissez vos places libres.';

  @override
  String get homePostRide => 'Publier un trajet';

  @override
  String get homeFindTitle => 'Trouver un trajet';

  @override
  String get homeFindSubtitle =>
      'Recherchez les trajets disponibles près de vous et réservez instantanément.';

  @override
  String get homeSearchRides => 'Rechercher un trajet';

  @override
  String get loginTitle => 'Heureux de vous revoir';

  @override
  String get loginSubtitle =>
      'Connectez-vous pour trouver ou proposer votre prochain trajet.';

  @override
  String get newToAlonzy => 'Nouveau sur Alonzy ?';

  @override
  String get createAnAccount => 'Créer un compte';

  @override
  String get emailLabel => 'Courriel';

  @override
  String get phoneTab => 'Téléphone';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get enterEmailAndPassword =>
      'Saisissez votre courriel et votre mot de passe.';

  @override
  String get enterPhoneNumber => 'Saisissez votre numéro de téléphone.';

  @override
  String get enterReceivedCode => 'Saisissez le code reçu.';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get phoneNumberHint => 'Ex. : +15145550123';

  @override
  String get phoneCodeExplanation =>
      'Nous vous enverrons par SMS un code à usage unique pour vous connecter.';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get verificationCodeLabel => 'Code de vérification';

  @override
  String get verificationCodeHint => 'Code à 6 chiffres';

  @override
  String get changePhoneNumber => 'Changer de numéro de téléphone';

  @override
  String get verifyAndSignIn => 'Vérifier et se connecter';

  @override
  String get signupTitle => 'Créer votre compte';

  @override
  String get signupSubtitle => 'Commencez en moins d’une minute.';

  @override
  String get signupTermsNotice =>
      'En continuant, vous acceptez nos conditions d’utilisation et notre politique de confidentialité.';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String get optionalPhoneLabel => 'Téléphone (facultatif)';

  @override
  String get passwordLengthHint => 'Au moins 6 caractères';

  @override
  String get createAccount => 'Créer le compte';

  @override
  String get signupValidation =>
      'Saisissez un courriel valide et un mot de passe d’au moins 6 caractères.';

  @override
  String get accountCreated =>
      'Compte créé. Consultez vos courriels pour confirmer votre adresse avant de vous connecter.';

  @override
  String get authIncorrectCredentials => 'Courriel ou mot de passe incorrect.';

  @override
  String get authAccountExists => 'Un compte existe déjà avec ce courriel.';

  @override
  String get authEmailNotConfirmed =>
      'Confirmez votre adresse courriel avant de vous connecter.';

  @override
  String get authInvalidEmail => 'Vérifiez votre adresse courriel.';

  @override
  String get authInvalidPhone =>
      'Vérifiez votre numéro de téléphone, y compris l’indicatif du pays.';

  @override
  String get authInvalidCode =>
      'Le code est invalide ou a expiré. Demandez un nouveau code.';

  @override
  String get authRateLimited =>
      'Trop de tentatives. Patientez un moment avant de réessayer.';

  @override
  String get authWeakPassword => 'Choisissez un mot de passe plus robuste.';

  @override
  String get authLoginFailed =>
      'Connexion impossible. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get authSignupFailed =>
      'Création du compte impossible. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get authSendCodeFailed =>
      'Envoi du code impossible. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get authVerifyCodeFailed =>
      'Vérification du code impossible. Réessayez ou demandez un nouveau code.';

  @override
  String get searchRoadToggle => 'Classer par détour routier (OSRM)';

  @override
  String get searchRoadNearbyHint =>
      'Présélection PostGIS : départs dans un rayon de 10 km autour de votre départ. La destination est évaluée par OSRM.';

  @override
  String searchRoadHelp(int limit, int km) {
    return 'Sélectionnez les deux adresses suggérées et une date. Les coordonnées du passager et des offres sont envoyées au serveur OSRM public et peuvent être journalisées. Prototype : au plus $limit offres présélectionnées et $km km de détour supplémentaire. Estimations sans trafic en temps réel.';
  }

  @override
  String get searchRoadRequired =>
      'Pour OSRM, sélectionnez le départ et la destination dans les suggestions, puis choisissez une date.';

  @override
  String searchRoadTooMany(int limit) {
    return 'Plus de $limit offres présélectionnées. Affinez la recherche (date, prix ou places), ou désactivez OSRM. Aucun classement routier partiel n’est affiché.';
  }

  @override
  String get searchRoadFailed =>
      'Calcul routier indisponible. Réessayez ou désactivez OSRM pour utiliser la recherche normale. Aucun classement de remplacement n’a été affiché.';

  @override
  String get searchRoadLoading => 'Calcul des détours OSRM…';

  @override
  String searchRoadResults(int count, int excluded) {
    return 'Tri OSRM par détour supplémentaire parmi les offres présélectionnées. Offres retenues : $count. Offres non retenues : $excluded.';
  }

  @override
  String get searchRoadEmpty =>
      'Aucune offre présélectionnée ne respecte le détour maximal de 15 km, ou aucun itinéraire exploitable n’a été trouvé.';

  @override
  String searchRoadDetour(String km, int minutes) {
    return 'Détour conducteur estimé (OSRM) : +$km km · +$minutes min';
  }

  @override
  String get searchRoadAttribution =>
      'Itinéraires : OSRM. Données : © contributeurs OpenStreetMap (ODbL).\nhttps://project-osrm.org/\nhttps://www.openstreetmap.org/copyright\nCorriger la carte : https://www.openstreetmap.org/fixthemap';
}
