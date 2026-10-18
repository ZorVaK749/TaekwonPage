package tech.zvk.taekwonpage.content.persistence;

import java.util.List;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;
import tech.zvk.taekwonpage.content.api.CitationResponse;

public interface ContentSourceRepository extends Repository<ContentSource, String> {
    @Query("""
        select new tech.zvk.taekwonpage.content.api.CitationResponse(
            c.id, c.sourceId, c.sourceSha256,
            s.title, s.organization, s.author, s.edition, s.language,
            c.pdfPage, c.printedPage, c.section,
            c.reviewStatus, s.reviewStatus, s.redistributionStatus)
        from ContentSource c join SourceDocument s
            on s.id = c.sourceId and s.sha256 = c.sourceSha256
        where c.contentId = :contentId
        order by c.id
        """)
    List<CitationResponse> findCitationsByContentId(@Param("contentId") String contentId);
}
