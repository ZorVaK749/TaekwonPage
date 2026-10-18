package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "source_document")
public class SourceDocument {
    @Id
    @Column(columnDefinition = "canonical_id")
    private String id;
    @Column(columnDefinition = "text")
    private String sha256;
    @Column(columnDefinition = "text")
    private String title;
    @Column(columnDefinition = "text")
    private String organization;
    @Column(columnDefinition = "text")
    private String author;
    @Column(columnDefinition = "text")
    private String edition;
    @Column(columnDefinition = "text")
    private String language;
    @Column(name = "review_status", columnDefinition = "text")
    private String reviewStatus;
    @Column(name = "redistribution_status", columnDefinition = "text")
    private String redistributionStatus;

    protected SourceDocument() { }
}
