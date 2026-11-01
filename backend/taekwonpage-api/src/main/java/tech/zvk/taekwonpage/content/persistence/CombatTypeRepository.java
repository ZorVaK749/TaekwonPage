package tech.zvk.taekwonpage.content.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.Repository;

public interface CombatTypeRepository extends Repository<CombatType, String> {
    @EntityGraph(attributePaths = "content")
    Optional<CombatType> findById(String id);
}
