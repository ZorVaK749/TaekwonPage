package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Immutable
@Table(name = "vocabulary")
public class Vocabulary {
    @Id
    @Column(columnDefinition = "canonical_id")
    private String id;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id", insertable = false, updatable = false)
    private ContentEntry content;
    @Column(columnDefinition = "text")
    private String translation;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(columnDefinition = "text[]")
    private String[] aliases;

    protected Vocabulary() { }

    public String getId() { return id; }
    public ContentEntry getContent() { return content; }
    public String getTranslation() { return translation; }
    public String[] getAliases() { return aliases; }
}
