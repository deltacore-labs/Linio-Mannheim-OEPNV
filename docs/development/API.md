# Linio - API Integration

## Übersicht

Linio verwendet die RNV GraphQL API für Echtzeit-ÖPNV-Daten.

## Authentifizierung

### Azure AD OAuth 2.0 Client Credentials Flow

```swift
// AuthService.swift
POST https://login.microsoftonline.com/{tenantID}/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id={clientID}
&client_secret={clientSecret}
&resource={resourceID}
```

### Token-Verwaltung

- Token werden im Keychain gespeichert
- Automatische Erneuerung vor Ablauf
- Token-Sharing mit Watch via WatchConnectivity

## GraphQL API

### Endpoint

```
https://graphql-sandbox-dds.rnv-online.de/
```

### Haupt-Queries

#### Verbindungssuche

```graphql
query Connections(
  $originGlobalID: String!,
  $destinationGlobalID: String!,
  $dateTime: DateTime!,
  $isDeparture: Boolean!,
  $limit: Int
) {
  trip {
    trips(
      originGlobalId: $originGlobalID,
      destinationGlobalId: $destinationGlobalID,
      dateTime: $dateTime,
      isDeparture: $isDeparture,
      limit: $limit
    ) {
      trips {
        id
        legs { ... }
      }
    }
  }
}
```

#### Abfahrten

```graphql
query Departures(
  $globalID: String!,
  $dateTime: DateTime!,
  $limit: Int
) {
  stop(globalId: $globalID) {
    departures(dateTime: $dateTime, limit: $limit) {
      line { ... }
      scheduledTime
      realtimeTime
      platform
    }
  }
}
```

#### Haltestellensuche

```graphql
query StationSearch($searchTerm: String!, $limit: Int) {
  stations(searchTerm: $searchTerm, limit: $limit) {
    globalId
    name
    latitude
    longitude
  }
}
```

## Service-Struktur

```
GraphQLService.swift         # Basis-Client, Apollo Setup
GraphQLService+Connections   # Verbindungssuche
GraphQLService+Departures    # Abfahrtsmonitor
GraphQLService+Stations      # Haltestellensuche
```

## Fehlerbehandlung

```swift
enum NetworkError: Error {
    case noInternet        // Keine Verbindung
    case timeout           // Request Timeout
    case serverError       // 5xx Status
    case graphQLError(msg) // GraphQL-Fehler
    case decodingError     // JSON-Parsing
}
```

## Caching

- **In-Memory**: Häufige Queries (Stationen)
- **UserDefaults**: Letzte Suchen, Favoriten
- **Widget-Refresh**: Alle 15 Minuten

## Rate Limiting

Die API hat keine dokumentierten Limits, aber:
- Auto-Refresh: max. alle 60 Sekunden
- Widget-Updates: alle 15 Minuten
- Debouncing bei Suche: 300ms

## Secrets-Management

Credentials werden verschlüsselt gespeichert:

```swift
// EncryptedSecrets.json (verschlüsselt)
{
  "RNV_CLIENT_ID": "encrypted...",
  "RNV_CLIENT_SECRET": "encrypted...",
  "RNV_TENANT_ID": "encrypted...",
  "RNV_RESOURCE": "encrypted..."
}
```

Entschlüsselung via `SecureConfigurationManager` mit AES-GCM.
