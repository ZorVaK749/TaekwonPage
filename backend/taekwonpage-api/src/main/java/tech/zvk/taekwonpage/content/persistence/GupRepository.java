package tech.zvk.taekwonpage.content.persistence;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

public interface GupRepository extends Repository<Gup, String> {
    @EntityGraph(attributePaths = "content")
    Optional<Gup> findByNumber(Integer number);

    // The seven observed requirement groups, in the same stable order the
    // curriculum_requirements_snapshot SQL function uses for revisions.
    @Query(value = "SELECT position_id FROM gup_position WHERE gup_id = :id ORDER BY position_id COLLATE \"C\"", nativeQuery = true)
    List<String> findPositionIds(@Param("id") String id);

    @Query(value = "SELECT theory_id FROM gup_theory WHERE gup_id = :id ORDER BY theory_id COLLATE \"C\"", nativeQuery = true)
    List<String> findTheoryIds(@Param("id") String id);

    @Query(value = "SELECT vocabulary_id FROM gup_vocabulary WHERE gup_id = :id ORDER BY vocabulary_id COLLATE \"C\"", nativeQuery = true)
    List<String> findVocabularyIds(@Param("id") String id);

    @Query(value = "SELECT tool_id FROM gup_tool WHERE gup_id = :id ORDER BY tool_id COLLATE \"C\"", nativeQuery = true)
    List<String> findBodyToolIds(@Param("id") String id);

    @Query(value = "SELECT kick_id FROM gup_kick WHERE gup_id = :id ORDER BY kick_id COLLATE \"C\"", nativeQuery = true)
    List<String> findKickIds(@Param("id") String id);

    @Query(value = "SELECT tul_id FROM gup_tul WHERE gup_id = :id ORDER BY tul_id COLLATE \"C\"", nativeQuery = true)
    List<String> findTulIds(@Param("id") String id);

    @Query(value = "SELECT combat_id FROM gup_combat WHERE gup_id = :id ORDER BY combat_id COLLATE \"C\"", nativeQuery = true)
    List<String> findCombatIds(@Param("id") String id);
}
