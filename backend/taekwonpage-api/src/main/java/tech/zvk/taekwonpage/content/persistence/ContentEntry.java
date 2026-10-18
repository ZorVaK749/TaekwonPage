package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "content_entry")
public class ContentEntry {
    @Id
    @Column(columnDefinition = "canonical_id")
    private String id;
    @Column(name = "content_type", columnDefinition = "text")
    private String contentType;
    @Column(columnDefinition = "text")
    private String name;
    @Column(columnDefinition = "text")
    private String description;
    @Column(name = "review_status", columnDefinition = "text")
    private String reviewStatus;

    protected ContentEntry() { }

    public String getName() { return name; }
    public String getDescription() { return description; }
    public String getReviewStatus() { return reviewStatus; }
}
