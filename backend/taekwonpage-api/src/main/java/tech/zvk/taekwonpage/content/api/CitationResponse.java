package tech.zvk.taekwonpage.content.api;

// Metadata about the observed copy, never a link to its local PDF.
public record CitationResponse(
    String id, String sourceId, String sourceSha256,
    String sourceTitle, String sourceOrganization, String sourceAuthor,
    String sourceEdition, String sourceLanguage,
    Integer pdfPage, String printedPage, String section,
    String reviewStatus, String sourceReviewStatus, String redistributionStatus
) { }
