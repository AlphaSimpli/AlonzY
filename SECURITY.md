# Security

AlonzY handles account, trip, and location data. Use a dedicated development
Supabase project while evaluating the application, and review database
migrations and access policies before deployment.

## Credential handling

- Keep local `.env` files out of version control; `.env.example` contains
  placeholders for required configuration.
- The Supabase anon/publishable key is a client identifier, not an authorization
  boundary. Access control must be enforced by authentication and Row-Level
  Security (RLS).
- Never place a Supabase `service_role` key or other server secret in the
  Flutter app, web tracker, or a public repository.
- The app bundles its client configuration for runtime use. Do not treat
  `.env` as encrypted storage.

## Location and safety sharing

- Live location sharing requires explicit in-app consent.
- External safety links are bearer links: anyone with an active link may view
  its permitted trip information until it expires or is revoked.
- Sharing is configured to expire after three hours and can be revoked by the
  user. Review [LIVE_SAFETY_TRACK.md](LIVE_SAFETY_TRACK.md) and the associated
  RLS policies before changing this flow.
- OSRM receives the route coordinates needed to estimate detours. Select a
  routing endpoint whose privacy and operational terms suit your deployment.

## Reporting a vulnerability

Please do not publish exploitable details in a public issue. Use GitHub's
private vulnerability reporting for this repository when available, or contact
the maintainers privately through the repository organization.

## Before deployment

1. Apply reviewed migrations to a non-production environment first.
2. Verify RLS policies for every user-facing table and RPC.
3. Configure only public Supabase client values in the Flutter and Pages
   deployments; keep server secrets in protected server-side settings.
4. Confirm tracker URLs, token expiry, consent, revocation, and platform
   location permissions.
5. Avoid logging credentials, access tokens, exact locations, or row contents.

# Sécurité

AlonzY traite des données de compte, de trajet et de localisation. Utilisez un
projet Supabase de développement dédié pour évaluer l’application et vérifiez
les migrations et les politiques d’accès avant tout déploiement.

## Gestion des identifiants

- Gardez les fichiers `.env` locaux hors du contrôle de version;
  `.env.example` ne contient que des valeurs fictives.
- La clé anon/publishable de Supabase est un identifiant client, pas une
  frontière d’autorisation. Le contrôle d’accès doit reposer sur
  l’authentification et les politiques RLS.
- N’inscrivez jamais une clé Supabase `service_role` ou un secret serveur dans
  l’application Flutter, le suivi web ou un dépôt public.
- L’application inclut sa configuration client pour l’exécution. `.env` n’est
  pas un stockage chiffré.

## Partage de localisation et de sécurité

- Le partage de position en direct exige un consentement explicite dans
  l’application.
- Les liens de sécurité externes sont des liens porteurs : toute personne qui
  détient un lien actif peut voir les renseignements permis jusqu’à son
  expiration ou sa révocation.
- Le partage expire après trois heures et peut être révoqué par l’utilisateur.
  Consultez [LIVE_SAFETY_TRACK.md](LIVE_SAFETY_TRACK.md) et les politiques RLS
  associées avant de modifier ce flux.
- OSRM reçoit les coordonnées nécessaires à l’estimation des détours.
  Choisissez un point de terminaison dont les pratiques de confidentialité et
  les conditions opérationnelles conviennent au déploiement.

## Signaler une vulnérabilité

Ne publiez pas de détails exploitables dans un problème public. Utilisez le
signalement privé de vulnérabilités GitHub si cette fonction est activée pour
le dépôt, ou contactez les responsables en privé par l’organisation GitHub.

## Avant le déploiement

1. Appliquez d’abord les migrations vérifiées dans un environnement hors
   production.
2. Vérifiez les politiques RLS de chaque table et procédure RPC accessible aux
   utilisateurs.
3. Configurez uniquement les valeurs publiques du client Supabase dans Flutter
   et Pages; conservez les secrets serveur dans des paramètres protégés côté
   serveur.
4. Vérifiez les URL de suivi, l’expiration et la révocation des jetons, le
   consentement et les permissions de localisation des plateformes.
5. Évitez de journaliser des identifiants, jetons d’accès, positions précises ou
   contenus de lignes.
