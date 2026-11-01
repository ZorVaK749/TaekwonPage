package tech.zvk.taekwonpage.content.api;

import java.util.List;

public record GupResponse(
    String id, int gup, String name, String description, String reviewStatus,
    Requirements requirements, List<CitationResponse> citations
) {
    // The seven groups exactly as the draft schema stores them; empty means
    // not yet linked, never an invitation to fill them from elsewhere.
    public record Requirements(
        List<String> positionIds, List<String> theoryIds, List<String> vocabularyIds,
        List<String> bodyToolIds, List<String> kickIds, List<String> tulIds, List<String> combatIds
    ) {
        public Requirements {
            positionIds = List.copyOf(positionIds);
            theoryIds = List.copyOf(theoryIds);
            vocabularyIds = List.copyOf(vocabularyIds);
            bodyToolIds = List.copyOf(bodyToolIds);
            kickIds = List.copyOf(kickIds);
            tulIds = List.copyOf(tulIds);
            combatIds = List.copyOf(combatIds);
        }
    }

    public GupResponse {
        citations = List.copyOf(citations);
    }
}
