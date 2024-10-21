import Foundation

// MARK: - Welcome
struct UserProfile: Codable {
    let id, rev, userName, accountStatus: String
    //let effectiveRoles, effectiveAssignments: [String]?
    let postalCode, stateProvince, postalAddress, displayName, country, city, givenName, sn, telephoneNumber, mail, frIndexedString1, frIndexedString2, frIndexedString3, frIndexedString4, frIndexedString5, frUnindexedString1, frUnindexedString2, frUnindexedString3, frUnindexedString4, frUnindexedString5: String?
    let frIndexedMultivalued1, frIndexedMultivalued2, frIndexedMultivalued3, frIndexedMultivalued4, frIndexedMultivalued5, frUnindexedMultivalued1, frUnindexedMultivalued2, frUnindexedMultivalued3, frUnindexedMultivalued4, frUnindexedMultivalued5: [String]?
    let frIndexedDate1, frIndexedDate2, frIndexedDate3, frIndexedDate4, frIndexedDate5, frUnindexedDate1, frUnindexedDate2, frUnindexedDate3: String?
    let frUnindexedDate4, frUnindexedDate5, frIndexedInteger1, frIndexedInteger2, frIndexedInteger3, frIndexedInteger4, frIndexedInteger5, frUnindexedInteger1, frUnindexedInteger2, frUnindexedInteger3, frUnindexedInteger4, frUnindexedInteger5: Int?
    let consentedMappings: [ConsentMapping]
    let preferences: Preferences?
    let aliasList: [String]
    let memberOfOrgIDs: [String]
    let isMemberOf: [String]?
    let profileImage: String?
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case rev = "_rev"
        //case userName, accountStatus, effectiveRoles, effectiveAssignments, postalCode, stateProvince, postalAddress, displayName
        case userName, accountStatus, postalCode, stateProvince, postalAddress, displayName, profileImage
        case country, city, givenName, sn, telephoneNumber, mail, isMemberOf, frIndexedString1, frIndexedString2, frIndexedString3, frIndexedString4, frIndexedString5, frUnindexedString1, frUnindexedString2, frUnindexedString3, frUnindexedString4, frUnindexedString5, frIndexedMultivalued1, frIndexedMultivalued2, frIndexedMultivalued3, frIndexedMultivalued4, frIndexedMultivalued5, frUnindexedMultivalued1, frUnindexedMultivalued2, frUnindexedMultivalued3, frUnindexedMultivalued4, frUnindexedMultivalued5, frIndexedDate1, frIndexedDate2, frIndexedDate3, frIndexedDate4, frIndexedDate5, frUnindexedDate1, frUnindexedDate2, frUnindexedDate3, frUnindexedDate4, frUnindexedDate5, frIndexedInteger1, frIndexedInteger2, frIndexedInteger3, frIndexedInteger4, frIndexedInteger5, frUnindexedInteger1, frUnindexedInteger2, frUnindexedInteger3, frUnindexedInteger4, frUnindexedInteger5, consentedMappings, preferences, aliasList, memberOfOrgIDs
    }
}

// MARK: - Preferences
struct Preferences: Codable {
    let marketing, updates: Bool?
}

struct ConsentMapping: Codable {
  let consentDate, mapping: String
}

// MARK: - Patch
struct PatchString: Codable {
    let field, operation, value: String
}

struct PatchBoolean: Codable {
    let field, operation: String
    let value: Bool
}
