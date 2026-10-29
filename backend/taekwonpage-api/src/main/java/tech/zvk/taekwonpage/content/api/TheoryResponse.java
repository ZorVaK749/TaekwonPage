package tech.zvk.taekwonpage.content.api;

import java.util.List;

public record TheoryResponse(
    String id, String name, String description, String reviewStatus,
    List<CitationResponse> citations
) {
    public TheoryResponse {
        citations = List.copyOf(citations);
    }
}
