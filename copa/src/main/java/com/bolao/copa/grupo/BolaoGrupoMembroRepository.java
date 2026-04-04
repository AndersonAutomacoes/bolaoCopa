package com.bolao.copa.grupo;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BolaoGrupoMembroRepository extends JpaRepository<BolaoGrupoMembro, BolaoGrupoMembroId> {

    boolean existsByBolaoIdAndUserId(Long bolaoId, Long userId);

    List<BolaoGrupoMembro> findByBolaoId(Long bolaoId);

    List<BolaoGrupoMembro> findByUserId(Long userId);
}
