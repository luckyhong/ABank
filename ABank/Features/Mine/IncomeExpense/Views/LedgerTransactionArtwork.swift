import UIKit

/// Shared by list and detail so one transaction always uses the same artwork.
/// Uses business categories instead of merchant names or legacy SF Symbol keys.
enum LedgerTransactionArtwork {
    static func image(for transaction: LedgerTransaction) -> UIImage? {
        let name: String
        switch transaction.categoryId {
        case "salary": name = "transaction_salary"
        case "third_party_out": name = "transaction_payment"
        case "transfer_out", "transfer_in":
            name = "transaction_transfer"
        case "self_transfer": name = "transaction_own_transfer"
        default:
            // Categories absent from the reference retain a meaningful outline fallback.
            return UIImage(systemName: transaction.direction == .income ? "arrow.down.left.circle" : "arrow.up.right.circle")?
                .withTintColor(.abankTextSecondary, renderingMode: .alwaysOriginal)
        }
        return UIImage.abankAsset("abc_mine_detail_\(name)", fallback: "arrow.left.arrow.right")
    }
}
