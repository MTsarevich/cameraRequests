import Foundation
import Observation

@MainActor
@Observable
final class LeadsListViewModel {
    var allLeads: [Lead] = []
    var selectedStatus: LeadStatus = .new
    var searchText: String = ""

    var counts: [LeadStatus: Int] {
        var dict: [LeadStatus: Int] = [:]
        for lead in allLeads {
            dict[lead.status, default: 0] += 1
        }
        return dict
    }

    func filteredLeads() -> [Lead] {
        let bySegment = allLeads.filter { $0.status == selectedStatus }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return bySegment }
        return bySegment.filter { $0.searchableHaystack.contains(query) }
    }

    func ingest(_ leads: [Lead]) {
        self.allLeads = leads
    }
}
