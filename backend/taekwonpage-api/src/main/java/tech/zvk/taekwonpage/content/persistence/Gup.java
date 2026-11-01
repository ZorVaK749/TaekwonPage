package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "gup")
public class Gup {
    @Id
    @Column(columnDefinition = "canonical_id")
    private String id;
    @Column(name = "gup")
    private Integer number;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id", insertable = false, updatable = false)
    private ContentEntry content;

    protected Gup() { }

    public String getId() { return id; }
    public Integer getNumber() { return number; }
    public ContentEntry getContent() { return content; }
}
