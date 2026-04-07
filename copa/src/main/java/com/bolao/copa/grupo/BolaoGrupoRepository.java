package com.bolao.copa.grupo;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BolaoGrupoRepository extends JpaRepository<BolaoGrupo, Long> {

    Optional<BolaoGrupo> findByCodigoConvite(String codigoConvite);

    List<BolaoGrupo> findByOwner_IdOrderByCreatedAtDesc(Long ownerId);

    List<BolaoGrupo> findByPublicoTrueOrderByCreatedAtDesc();
}
