// ===============================================================================
// [MODULE_NAME]: axie_graphql_queries.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Network Contracts
// [INTENT]: Validated GraphQL query strings using axpInfo for level extraction.
// [DEPENDENCIES]: None
// [ARCHITECTURE]: Stateless Data Contract
// ===============================================================================

class AxieGraphQLQueries {
  /// Single Axie detail query for direct ID search
  static const String getAxieDetail = r'''
    query GetAxieDetail($axieId: ID!) {
      axie(axieId: $axieId) {
        id
        name
        class
        stage
        image
        genes
        axpInfo {
          level
        }
        parts {
          id
          name
          class
          type
        }
        stats {
          hp
          speed
          skill
          morale
        }
      }
    }
  ''';

  /// Wallet ownership query returning full Axie metadata in a single round-trip
  static const String getAxiesByOwner = r'''
    query GetAxiesByOwner($owner: String!, $from: Int, $size: Int) {
      axies(owner: $owner, from: $from, size: $size) {
        total
        results {
          id
          name
          class
          stage
          image
          genes
          axpInfo {
            level
          }
          parts {
            id
            name
            class
            type
          }
          stats {
            hp
            speed
            skill
            morale
          }
        }
      }
    }
  ''';
}
