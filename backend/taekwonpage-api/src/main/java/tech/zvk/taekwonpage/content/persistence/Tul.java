package tech.zvk.taekwonpage.content.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

// TUL or partial exercise draft; a null movement_count means the count is still unknown.
@Entity
@Immutable
@Table(name = "tul")
public class Tul {
    @Id
    @Column(columnDefinition = "canonical_id")
    private String id;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id", insertable = false, updatable = false)
    private ContentEntry content;
    @Column(name = "movement_count")
    private Integer movementCount;
    @Column(name = "initial_position_id", columnDefinition = "canonical_id")
    private String initialPositionId;
    @Column(name = "sequence_complete")
    private boolean sequenceComplete;
    @Column(name = "sequence_scope", columnDefinition = "text")
    private String sequenceScope;

    protected Tul() { }

    public String getId() { return id; }
    public ContentEntry getContent() { return content; }
    public Integer getMovementCount() { return movementCount; }
    public String getInitialPositionId() { return initialPositionId; }
    public boolean isSequenceComplete() { return sequenceComplete; }
    public String getSequenceScope() { return sequenceScope; }
}
