package tech.zvk.taekwonpage.content.api;

import java.util.List;

public record VocabularyResponse(
    String id, String name, String description, String reviewStatus,
    String translation, List<String> aliases,
    List<CitationResponse> citations
) {
    public VocabularyResponse {
        aliases = List.copyOf(aliases);
        citations = List.copyOf(citations);
    }
}
