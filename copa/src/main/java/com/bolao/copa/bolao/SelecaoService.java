package com.bolao.copa.bolao;

import com.bolao.copa.bolao.api.SelecaoCreateRequest;
import com.bolao.copa.bolao.api.SelecaoResponse;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class SelecaoService {

    private final SelecaoRepository selecaoRepository;

    public SelecaoService(SelecaoRepository selecaoRepository) {
        this.selecaoRepository = selecaoRepository;
    }

    @Transactional(readOnly = true)
    public List<SelecaoResponse> list() {
        return selecaoRepository.findAll(Sort.by(Sort.Direction.ASC, "nome")).stream()
                .map(BolaoMapper::toSelecaoResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public SelecaoResponse getById(Long id) {
        Selecao selecao = selecaoRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Seleção não encontrada"));
        return BolaoMapper.toSelecaoResponse(selecao);
    }

    @Transactional
    public SelecaoResponse create(SelecaoCreateRequest request) {
        if (selecaoRepository.existsByNomeIgnoreCase(request.nome().trim())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Seleção já cadastrada");
        }
        Selecao selecao = new Selecao(request.nome().trim(), request.bandeiraUrl());
        return BolaoMapper.toSelecaoResponse(selecaoRepository.save(selecao));
    }
}
