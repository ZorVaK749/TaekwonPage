package tech.zvk.taekwonpage.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

// The four documented roles (informe, section 6). Role and martial grade stay
// independent: this table never stores a gup.
@Entity
@Table(name = "role")
public class Role {
    @Id
    @Column(name = "name", columnDefinition = "text", nullable = false)
    private String name;

    protected Role() {
        // JPA
    }

    public String name() {
        return name;
    }
}
