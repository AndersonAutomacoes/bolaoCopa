package com.bolao.copa.bolao;

import com.bolao.copa.bolao.api.SelecaoCreateRequest;
import com.bolao.copa.bolao.api.SelecaoResponse;
import com.bolao.copa.bolao.api.SelecaoUpdateRequest;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class SelecaoService {

    private final SelecaoRepository selecaoRepository;
    private final JogoRepository jogoRepository;

    public SelecaoService(SelecaoRepository selecaoRepository, JogoRepository jogoRepository) {
        this.selecaoRepository = selecaoRepository;
        this.jogoRepository = jogoRepository;
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

    @Transactional
    public SelecaoResponse update(Long id, SelecaoUpdateRequest request) {
        Selecao selecao = selecaoRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Seleção não encontrada"));
        if (request.nome() != null) {
            String nome = request.nome().trim();
            if (selecaoRepository.existsByNomeIgnoreCase(nome) && !nome.equalsIgnoreCase(selecao.getNome())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Seleção já cadastrada");
            }
            selecao.setNome(nome);
        }
        if (request.bandeiraUrl() != null) {
            selecao.setBandeiraUrl(request.bandeiraUrl());
        }
        return BolaoMapper.toSelecaoResponse(selecaoRepository.save(selecao));
    }

    @Transactional
    public void delete(Long id) {
        if (!selecaoRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Seleção não encontrada");
        }
        if (jogoRepository.existsBySelecaoCasaId(id) || jogoRepository.existsBySelecaoForaId(id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Seleção referenciada por jogos");
        }
        selecaoRepository.deleteById(id);
    }
}
