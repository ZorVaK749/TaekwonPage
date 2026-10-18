package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "content_source")
public class ContentSource {
    @Id
    @Column(columnDefinition = "canonical_id")
    private String id;
    @Column(name = "content_id", columnDefinition = "canonical_id")
    private String contentId;
    @Column(name = "source_id", columnDefinition = "canonical_id")
    private String sourceId;
    @Column(name = "source_sha256", columnDefinition = "text")
    private String sourceSha256;
    @Column(name = "pdf_page")
    private Integer pdfPage;
    @Column(name = "printed_page", columnDefinition = "text")
    private String printedPage;
    @Column(columnDefinition = "text")
    private String section;
    @Column(name = "review_status", columnDefinition = "text")
    private String reviewStatus;

    protected ContentSource() { }
}
