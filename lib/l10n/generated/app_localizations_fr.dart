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
  String get searchRoadToggle => 'Classer selon le score hybride (OSRM)';

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
    return 'Classement hybride des offres présélectionnées selon le détour, l’horaire et les préférences. Offres retenues : $count. Offres non retenues : $excluded.';
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

  @override
  String searchHybridDetour(int minutes, int score) {
    return 'Détour de $minutes min · compatibilité $score %';
  }

  @override
  String get searchPreferredTime => 'Heure souhaitée';

  @override
  String get searchChooseTime => 'Choisir l’heure souhaitée';

  @override
  String get searchRejectMatch => 'Refuser cette proposition';

  @override
  String get searchLearnedToggle => 'Utiliser le modèle appris (expérimental)';

  @override
  String get searchLearnedHelp =>
      'Classe les offres avec le modèle appris, en conservant les mêmes exclusions. Le score expérimental n’est pas une probabilité d’acceptation réelle.';

  @override
  String get searchLearnedSyntheticNotice =>
      'Ce modèle a été entraîné uniquement sur des données synthétiques. Ses performances avec de vrais utilisateurs ne sont pas établies.';

  @override
  String get searchLearnedLoading => 'Chargement du modèle expérimental…';

  @override
  String get searchLearnedFailed =>
      'Le modèle expérimental est indisponible. Réessayez ou désactivez cette option pour utiliser les règles. Aucun classement de remplacement n’a été affiché.';

  @override
  String searchLearnedResults(int count, int excluded) {
    return 'Classement expérimental par modèle appris, avec les mêmes exclusions que le classement à règles. Offres retenues : $count. Offres non retenues : $excluded.';
  }

  @override
  String searchLearnedScore(String score) {
    return 'Score du modèle expérimental : $score/100';
  }

  @override
  String searchRuleDetour(int minutes, int score) {
    return 'Détour de $minutes min · score à règles : $score/100';
  }

  @override
  String get profileSettingsTitle => 'Profil et paramètres';

  @override
  String get profileLanguage => 'Langue de l’application';

  @override
  String get profileEdit => 'Modifier le profil';

  @override
  String get profileAccountMode => 'Type de compte';

  @override
  String get profileDriverMode => 'Mode conducteur';

  @override
  String get profileDriverEnabled => 'Mode conducteur activé';

  @override
  String get profileDriverDisabled => 'Mode conducteur désactivé';

  @override
  String get profileDriverModeDescription =>
      'Vous pouvez publier et gérer des trajets';

  @override
  String get profileEnableDriverMode =>
      'Activez cette option pour publier des trajets';

  @override
  String get profileQuickActions => 'Raccourcis';

  @override
  String get profileSearchRides => 'Rechercher un trajet';

  @override
  String get profileSearchRidesDescription =>
      'Trouver et réserver des trajets disponibles';

  @override
  String get profileMyBookings => 'Mes réservations';

  @override
  String get profileMyBookingsDescription =>
      'Consulter vos réservations de trajet';

  @override
  String get profileMessages => 'Messages';

  @override
  String get profileMessagesDescription =>
      'Discuter avec les conducteurs et les passagers';

  @override
  String get profilePostRide => 'Publier un trajet';

  @override
  String get profilePostRideDescription => 'Créer une nouvelle offre de trajet';

  @override
  String get profileManageBookings => 'Gérer les réservations';

  @override
  String get profileManageBookingsDescription =>
      'Accepter ou refuser les réservations des passagers';

  @override
  String get profileMyPostedRides => 'Mes trajets publiés';

  @override
  String get profileNoPostedRides => 'Aucun trajet publié pour le moment';

  @override
  String get profileLogout => 'Se déconnecter';

  @override
  String get profileLoggedOut => 'Vous êtes déconnecté.';

  @override
  String get profileVerification => 'Vérification';

  @override
  String get profileNotProvided => 'Non renseigné';

  @override
  String get profileVerified => 'Vérifié';

  @override
  String get profileNotVerified => 'Non vérifié';

  @override
  String get profilePendingReview => 'En attente d’examen';

  @override
  String get profileVerifyNow => 'Vérifier maintenant';

  @override
  String get profileFullyVerified =>
      '🎉 Profil entièrement vérifié — vous êtes un membre de confiance.';

  @override
  String get profileVerificationEncouragement =>
      'Les membres vérifiés inspirent davantage confiance. La vérification est gratuite.';

  @override
  String profileRating(String rating) {
    return 'Note : $rating';
  }

  @override
  String get profileDriverBadge => 'Conducteur';

  @override
  String profileReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '$count avis',
    );
    return '$_temp0';
  }

  @override
  String profileCompletedTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trajets effectués',
      one: '$count trajet effectué',
    );
    return '$_temp0';
  }

  @override
  String get profileRideCancelledStatus => 'Annulé';

  @override
  String profileSeatsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places disponibles',
      one: '$count place disponible',
    );
    return '$_temp0';
  }

  @override
  String profilePricePerSeat(String price) {
    return '$price / place';
  }

  @override
  String get profileCancelRide => 'Annuler le trajet';

  @override
  String get profileCancelRideTitle => 'Annuler ce trajet ?';

  @override
  String profileCancelRideMessage(String origin, String destination) {
    return 'Le trajet de $origin à $destination ne sera plus affiché.';
  }

  @override
  String get profileKeepRide => 'Garder le trajet';

  @override
  String get profileRideCancelledNotice => 'Trajet annulé.';

  @override
  String get profileRideCancelFailed =>
      'Impossible d’annuler le trajet. Réessayez.';

  @override
  String get profileLoadFailed => 'Impossible de charger le profil. Réessayez.';

  @override
  String get profileUpdateFailed =>
      'Impossible de mettre à jour le profil. Réessayez.';

  @override
  String get profileVerifyIdTitle => 'Vérifier votre identité ?';

  @override
  String get profileVerifyIdMessage =>
      'Votre demande sera examinée par notre équipe de soutien. Cela contribue à renforcer la confiance dans la communauté.';

  @override
  String get profileNotNow => 'Pas maintenant';

  @override
  String get profileRequestVerification => 'Demander la vérification';

  @override
  String get profileVerificationRequested =>
      'Demande de vérification envoyée — en attente d’examen.';

  @override
  String get profileVerificationFailed =>
      'Impossible de demander la vérification. Réessayez.';

  @override
  String get profileDriverRideStatusAvailable => 'Disponible';

  @override
  String get profileDriverRideStatusInProgress => 'En cours';

  @override
  String get profileDriverRideStatusCompleted => 'Terminé';

  @override
  String get profileDriverRideStatusOther => 'Autre';

  @override
  String get myBookings => 'Mes réservations';

  @override
  String get myBookingsUpcoming => 'À venir';

  @override
  String get myBookingsPast => 'Passés';

  @override
  String get myBookingsEmptyUpcoming => 'Aucune réservation à venir';

  @override
  String get myBookingsEmptyPast => 'Aucune réservation passée';

  @override
  String get myBookingsBrowseRides =>
      'Explorez les trajets disponibles et réservez !';

  @override
  String get myBookingsHistoryHint =>
      'L’historique de vos trajets apparaîtra ici.';

  @override
  String get myBookingsLoadFailed =>
      'Impossible de charger vos réservations. Réessayez.';

  @override
  String get myBookingsCancelTitle => 'Annuler la réservation ?';

  @override
  String get myBookingsCancelConfirm =>
      'Voulez-vous vraiment annuler cette réservation ?';

  @override
  String get myBookingsKeep => 'Garder la réservation';

  @override
  String get myBookingsCancel => 'Annuler la réservation';

  @override
  String get myBookingsCancelled => 'Réservation annulée.';

  @override
  String get myBookingsCancelFailed =>
      'Impossible d’annuler la réservation. Réessayez.';

  @override
  String myBookingsRateDriver(String driver) {
    return 'Évaluer $driver';
  }

  @override
  String get myBookingsCommentOptional => 'Commentaire (facultatif)';

  @override
  String get myBookingsTripFeedbackHint => 'Comment s’est passé le trajet ?';

  @override
  String get myBookingsSubmit => 'Envoyer';

  @override
  String get myBookingsReviewThanks => 'Merci pour votre évaluation.';

  @override
  String get myBookingsReviewFailed =>
      'Impossible d’envoyer votre évaluation. Réessayez.';

  @override
  String get myBookingsChatFailed =>
      'Impossible d’ouvrir la conversation. Réessayez.';

  @override
  String get myBookingsStart => 'Départ';

  @override
  String get myBookingsEnd => 'Arrivée';

  @override
  String myBookingsDeparture(String date, String time) {
    return 'Départ : $date à $time';
  }

  @override
  String get myBookingsDriver => 'Conducteur';

  @override
  String myBookingsDriverRating(String driver, String rating) {
    return '$driver ($rating ⭐)';
  }

  @override
  String get myBookingsYourBooking => 'Votre réservation';

  @override
  String myBookingsSeatsAndTotal(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '$count place',
    );
    return '$_temp0 · $price';
  }

  @override
  String myBookingsPickup(String location) {
    return 'Prise en charge : $location';
  }

  @override
  String get myBookingsAwaitingApproval =>
      'En attente de l’approbation du conducteur';

  @override
  String get myBookingsLiveTrack => 'Suivi de sécurité en direct';

  @override
  String get myBookingsMessage => 'Message';

  @override
  String get myBookingsRateAction => 'Évaluer le conducteur';

  @override
  String get myBookingsConfirmedStatus => 'Confirmée';

  @override
  String get myBookingsPendingStatus => 'En attente';

  @override
  String get myBookingsCompletedStatus => 'Terminée';

  @override
  String get myBookingsCancelledStatus => 'Annulée';

  @override
  String get myBookingsRejectedStatus => 'Refusée';

  @override
  String get myBookingsOtherStatus => 'Autre';

  @override
  String get languageSaveFailed =>
      'Impossible d’enregistrer la langue choisie. Réessayez.';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get editProfilePersonalInfo => 'Renseignements personnels';

  @override
  String get editProfileFirstName => 'Prénom';

  @override
  String get editProfileLastName => 'Nom';

  @override
  String get editProfilePhone => 'Téléphone';

  @override
  String get editProfileBio => 'À propos de moi';

  @override
  String get editProfileBioHint => 'Parlez un peu de vous aux passagers';

  @override
  String get editProfileContactMethod => 'Moyen de contact préféré';

  @override
  String get editProfileEmail => 'Courriel';

  @override
  String get editProfilePhoneContact => 'Téléphone';

  @override
  String get editProfileInAppChat => 'Messagerie de l’application';

  @override
  String get editProfileVehicle => 'Mon véhicule';

  @override
  String get editProfileVehicleHint =>
      'Ces renseignements préremplissent vos offres et sont visibles aux passagers.';

  @override
  String get editProfileMake => 'Marque';

  @override
  String get editProfileMakeHint => 'Ex. : Toyota';

  @override
  String get editProfileModel => 'Modèle';

  @override
  String get editProfileModelHint => 'Ex. : Corolla';

  @override
  String get editProfileColor => 'Couleur';

  @override
  String get editProfileColorHint => 'Ex. : blanc';

  @override
  String get editProfileYear => 'Année';

  @override
  String get editProfileYearHint => 'Ex. : 2022';

  @override
  String get editProfilePlate => 'Plaque';

  @override
  String get editProfilePlateHint => 'Ex. : ABC 123';

  @override
  String get editProfileSave => 'Enregistrer les modifications';

  @override
  String get editProfileSaving => 'Enregistrement…';

  @override
  String get editProfileSaved => 'Profil mis à jour.';

  @override
  String get editProfileSaveFailed =>
      'Impossible d’enregistrer le profil. Réessayez.';

  @override
  String get chatMessagesTitle => 'Messages';

  @override
  String get chatTitle => 'Conversation';

  @override
  String get chatRefresh => 'Actualiser';

  @override
  String get chatRetry => 'Réessayer';

  @override
  String get chatLoadFailed =>
      'Impossible de charger les conversations. Réessayez.';

  @override
  String get chatSendFailed => 'Impossible d’envoyer le message. Réessayez.';

  @override
  String get chatEmptyTitle => 'Aucune conversation pour le moment';

  @override
  String get chatEmptyMessage =>
      'Écrivez au conducteur d’un trajet ou à un passager de vos réservations pour commencer à discuter.';

  @override
  String get chatMember => 'Membre';

  @override
  String get chatNoMessages => 'Aucun message pour le moment';

  @override
  String get chatNow => 'À l’instant';

  @override
  String chatMinutesAgo(int minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String chatHoursAgo(int hours) {
    return 'Il y a $hours h';
  }

  @override
  String chatDaysAgo(int days) {
    return 'Il y a $days j';
  }

  @override
  String get chatThreadEmptyTitle => 'Aucun message pour le moment';

  @override
  String get chatThreadEmptyMessage =>
      'Dites bonjour et confirmez les détails de votre trajet.';

  @override
  String get chatPassenger => 'Passager';

  @override
  String chatBookingRequest(String passenger, int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: 'une place',
    );
    return '$passenger a demandé $_temp0 pour $price';
  }

  @override
  String get chatDecline => 'Refuser';

  @override
  String get chatAccept => 'Accepter';

  @override
  String get chatWriteMessage => 'Écrire un message…';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get driverBookingsTitle => 'Gérer les réservations';

  @override
  String get driverBookingsNoRidesTitle => 'Aucun trajet publié pour le moment';

  @override
  String get driverBookingsNoRidesMessage =>
      'Publiez un trajet pour recevoir des demandes de réservation.';

  @override
  String get driverBookingsLoadFailed =>
      'Impossible de charger les trajets et les réservations. Réessayez.';

  @override
  String get driverBookingsActionFailed =>
      'Cette action a échoué. Vérifiez votre connexion et réessayez.';

  @override
  String get driverBookingsAccepted => 'Réservation acceptée.';

  @override
  String get driverBookingsRejected => 'Réservation refusée.';

  @override
  String get driverBookingsCancelled => 'Réservation annulée.';

  @override
  String get driverBookingsRideCompleted => 'Trajet marqué comme terminé.';

  @override
  String driverBookingsDeparture(String date, String time) {
    return 'Départ : $date à $time';
  }

  @override
  String driverBookingsSeatsPrice(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '$count place',
    );
    return '$_temp0 · $price';
  }

  @override
  String get driverBookingsNoBookings => 'Aucune réservation pour le moment';

  @override
  String get driverBookingsLiveTrack => 'Suivi de sécurité en direct';

  @override
  String get driverBookingsCompleteRide => 'Marquer le trajet comme terminé';

  @override
  String get driverBookingsPassenger => 'Passager';

  @override
  String driverBookingsPhone(String phone) {
    return 'Téléphone : $phone';
  }

  @override
  String driverBookingsPickup(String location) {
    return 'Prise en charge : $location';
  }

  @override
  String get driverBookingsMessage => 'Message';

  @override
  String get driverBookingsReject => 'Refuser';

  @override
  String get driverBookingsAccept => 'Accepter';

  @override
  String get driverBookingsCancel => 'Annuler';

  @override
  String get safetyShareButton => 'Partager mon trajet en direct';

  @override
  String get safetyConsentTitle => 'Consentement au partage';

  @override
  String get safetyConsentMessage =>
      'Loi 25 du Québec : votre position GPS précise sera partagée avec toute personne détenant ce lien jusqu’à son expiration (3 heures) ou jusqu’à ce que vous arrêtiez le partage. Le lien n’exige pas de compte. Vous pouvez retirer votre consentement à tout moment en arrêtant le suivi.';

  @override
  String get safetyCancel => 'Annuler';

  @override
  String get safetyStartSharing => 'J’accepte et partager';

  @override
  String get safetyStopSharing => 'Arrêter le partage';

  @override
  String get safetySharingStarted => 'Le partage de position est actif.';

  @override
  String get safetySharingStopped => 'Le partage de position est arrêté.';

  @override
  String get safetyShareFailed =>
      'Impossible de démarrer le partage de position. Vérifiez les autorisations et réessayez.';

  @override
  String get safetyRideNotActive =>
      'Le suivi est disponible lorsque le trajet est en cours.';

  @override
  String get safetyTrackingTitle => 'Suivi et partage de sécurité';

  @override
  String get safetyTrackingStart => 'Suivi & partage de sécurité';

  @override
  String safetyTrackingParticipants(int count) {
    return '$count participant(s) sur la carte';
  }

  @override
  String get safetyTrackingVisibleBy =>
      'Votre position est visible par les participants du trajet et toute personne disposant de votre lien de suivi (expire dans 3 h).';

  @override
  String get safetyTrackingNotSharing => 'Votre position n’est pas partagée.';

  @override
  String get safetyTrackingSharing => 'Votre position est partagée en direct.';

  @override
  String get safetyTrackingCopyLink => 'Copier le lien';

  @override
  String get safetyTrackingSendLink => 'Envoyer à un proche';

  @override
  String get safetyTrackingLinkCopied => 'Lien de suivi copié.';

  @override
  String get safetyTrackingRecenter => 'Recentrer sur ma position';

  @override
  String get safetyTrackingStartLabel => 'Départ';

  @override
  String get safetyTrackingEndLabel => 'Arrivée';

  @override
  String get safetyTrackingMyPosition => 'Ma position';

  @override
  String get safetyTrackingParticipant => 'Participant';

  @override
  String get safetyTrackingLocationUnavailable =>
      'Impossible d’obtenir votre position. Vérifiez les autorisations de localisation.';
}
