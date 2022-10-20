### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ b820d04c-c209-47dc-badf-5087098e3476
begin
	using GraphPlot
	using Graphs,SimpleWeightedGraphs
	using Colors
	using DataStructures
	using PlutoUI
	using Compose

end

# ╔═╡ db7f3e0b-8ee6-4488-a0bf-a892158a58e5
md"""# Algoritmi per MST e SPT"""

# ╔═╡ 34812883-58e8-4e39-a7f4-2dbb36baa4e1
md"""
Nel notebook è illustrato tramite grafici interattivi il funzionamento di alcuni dei principali algoritmi che, basandosi su un grafo di esempio G pesato, indiretto e connesso, restituiscono l'**Albero dei cammini minimi (SPT)** e il **Minimo albero ricoprente (MST)** correlati ad esso.

Gli algoritmi in questione sono rispettivamente quello di **Dijkstra l'SPT** e quelli di **Prim, Reverse Delete e Kruskal per l'MST**  
"""

# ╔═╡ 58ca638a-af7a-4fd6-975d-b725d147a107
md"""**Grafo di esempio**"""

# ╔═╡ f14f9f40-ee82-49d7-b16f-a9920fae9cc6
md"""
Attraverso i seguenti sliders è possibile modificare il numero $|V|$ di nodi e $|E|$ di archi nel grafo su cui saranno dimostrati gli algoritmi.

Il numero di nodi è limitato a 10, mentre $|E|$ va da $\binom{N-1}{2} +1$ ossia il numero minimo di archi perchè il grafo sia connesso, a $\frac{(N(N-1))}{2}$ il massimo numero di archi nel grafo con N nodi.

Queste limitazioni sono state scelte per meglio mostrare il funzionamento degli algoritmi, e non influenzano il loro funzionamento.
"""

# ╔═╡ e55bf473-41e0-4459-a442-b54749cebfb5
	md"""
	Numero di Nodi V: $(@bind V Slider(4:10, show_value=true))
	"""

# ╔═╡ 88d329e1-c4f5-49e9-8447-1f5c9892fd5c
	md"""
	Numero di Archi E: $(@bind E Slider(((V-1)*(V-2)÷2)+1:(V*(V-1)÷2), show_value=true))
	"""

# ╔═╡ a8df7f90-40d3-11ed-2831-fb39b1be2aea
begin
	T = SimpleGraph(V,E)
	wg = SimpleWeightedGraph(T)
	for e ∈ edges(T)
		wg.weights[e.src, e.dst] = wg.weights[e.dst, e.src] = rand(1:1:20)
	end
	weights = weight.(collect(edges(wg)))
	locs_x, locs_y = spring_layout(wg)
	nodelabel = 1:nv(wg)
	colore_archi_visitati = 1
	colore_archi_da_visitare = 2
	colore_archi_scartati = 3
	colore_archi_sol = 4
	colore_nodi_visti = 5
	colore_nodi_visitati = 6
	nodecolor = [colorant"orange", colorant"lightgray",colorant"red",colorant"green",colorant"pink",colorant"blue"]
	grafo = compose(gplot(wg, nodelabel=nodelabel, locs_x, locs_y, edgelabel=weights,edgelabelc=colorant"black",EDGELABELSIZE=5),(context() , fontsize(24pt)))
	output = compose(grafo,(context(), rectangle(-10,-10,20,20), fill("white"), Compose.stroke("black")))
end

# ╔═╡ 04cb9eff-1da0-4a42-9c38-5e551146112c
md"""
# Algoritmo di Dijkstra per cammini minimi a singola sorgente

**Definizioni:** Sia G un grafo pesato  **(*diretto o non diretto*)** **$G(V,E,w)$** dove $V$ è l'insieme dei nodi, $E ⊆ V×V$ è l'insieme degli archi e $w$ funzione peso degli archi $w:E \to \mathbb{R}^+$.

Il **costo C** di un cammino *$\pi = <v_0,v_1...v_k>$* da $u$ a $v$ è $C(\pi) = \sum_{i = 1}^{k} \ w(v_{i-1}, v_i)$.

Un **cammino minimo** è quindi quello che ha costo **minore o uguale** a quello di ogni altro cammino con gli stessi vertici.

**(*L’unione* di tutti i cammini minimi da un vertice *u* a tutti i vertici da esso raggiungibili nel grafo $G$ genera un sottografo $T$ detto albero dei cammini minimi con sorgente in u)** in cui, per ogni $v \in V$,  $C(\pi(u,v)_T = \pi(u,v)_G$

**Problema:** Trovare il sottografo $T$ dei cammini minimi in un grafo pesato G
"""

# ╔═╡ e7d0b91c-7e2c-45fa-9407-f39924312acd
md"""
##### Dijkstra(G,nodoIniziale)

**L'algoritmo di Dijkstra** si basa sul mantenere una **stima per eccesso**  delle distanze $D_{sv}$ dall'origine $s$ a ciascun nodo $v$, un insieme $X$ di nodi per i quali $D_{sv}$ è accurata e un albero dei cammini minimi $T$ verso i nodi in $X$ 

Ad ogni passo dell'algoritmo, aggiungeremo ad $X$ il nodo *j* in $V-X$ per il quale la stima è *minima*. La stima con cui il nodo è stato inserito in $X$ diventa la distanza $D_{sj}$, e aggiungeremo l'arco che fornisce il valore minimo a $T$

Al termine dell'esecuzione dell'algoritmo avremo l'albero $T$ con i cammini minimi da *nodoIniziale* verso ciascun nodo.
"""

# ╔═╡ 0f112506-d940-4e90-8f4c-4fc2cb6f8ca0
md"""
#### Implementazione
L'algoritmo è implementato utilizzando una **coda con priorità** fornita della libreria *DataStructures*, e la libreria *SimpleWeightedGraphs* per rappresentare il grafo pesato G, che nel nostro caso è indiretto e connesso

All'inizio dell'esecuzione i valori di priorità di ciascun nodo nella coda saranno pari a **typemax(Float64)**, le loro distanze non sono ancora state stimate **(*Insert*)**.

Dopo l'inizializzazione degli array per la rappresentazione grafica l'elemento con priorità minore è rimosso dalla coda **(*DeleteMin*)**, ed è **stimata** la distanza dai nodi ad esso vicini. Questa nuova stima, qualora fosse migliore della precedente, la sostituirebbe **(*DecreaseKey*)**, mentre nel grafo T, aggiungiamo l'arco che va da *nodoAttuale* a *v*.

A questo punto inseriamo i risultati dello step appena compiuto negli array corrispondenti e procediamo con le iterazioni fin quando la coda con priorità sarà vuota, ad indicare che tutti i nodi sono stati visitati e sono nel set $X$ di cui conosco la distanza dal *nodoIniziale* e il corrispondente **cammino minimo**, che sarà presente in $T$.


"""

# ╔═╡ e21a230e-4ee8-4da5-abbf-61e56e1f5c7e
md"""
#### Costo
Utilizzando le code con priorità implementate con **Heap di Fibonacci** è possibile condurre un'**analisi ammortizzata** del costo dell'algoritmo, ossia l'analisi del costo rispetto all'intera sequenza di operazioni. 

In questo caso, considerando che avremo al più **n insert** , **n deleteMin**
ed **m decreaseKey** nella coda di priorità, con $m = |E|$, avremo i seguenti costi
"""

# ╔═╡ f5a1db0e-fe70-46f2-bed2-b5e70c043f7e
md"""
|    Insert  |    DeleteMin   |    DecreaseKey |
|:----------:|:--------------:|:--------------:|
|$\mathcal{O}(1)$|$\mathcal{O}(\log{}n)$ *    |$\mathcal{O}(1)$ *   |

**In totale il costo dell'algoritmo è** $n*\mathcal{O}(1)$ + $n*\mathcal{O}(\log{}n)$ + $\mathcal{O} (m)*\mathcal{O}(1)$ = $\mathcal{O}(m+ n\log{}n)$

"""

# ╔═╡ db6cecb4-f037-4c60-ba8e-1c35beb23b27
md"""
##### Grafici relativi all'esecuzione dell'algoritmo"""

# ╔═╡ 9b2c7452-c922-495c-998a-cbdcbbe70b9f
md"""
|       colore              | significato  |
|:-------------------------:|:------------:|
| $(nodecolor[2])        |elemento default|
| $(nodecolor[1])		| arco in frontiera   |
| $(nodecolor[3])   | arco scartato|
| $(nodecolor[4])       | arco in soluzione |
| $(nodecolor[5])        |nodo visto|
| $(nodecolor[6])        |nodo visitato|
"""

# ╔═╡ 18d76fcc-f805-4426-95e3-2792a79914dd
begin
	function Dijkstra(wg::SimpleWeightedGraph, nodoIniziale::Int)
	    ##init
	    T = SimpleGraph(nv(wg))
	    pq = PriorityQueue(1:nv(wg) .=> typemax(Float64)) #inizializzo la coda con 	priorità con numero di elementi pari al numero di vertici e a ciascuno assegno priorità massima.
		#array di array, ciascuno dei quali contiene le colorazioni degli archi e nodi in uno specifico passo dell'esecuzione
		colorearchi_steps = [fill(colore_archi_da_visitare,ne(wg))]
		colorenodi_steps = [fill(colore_archi_da_visitare,nv(wg))]
		colorenodi_steps[1][nodoIniziale] = colore_nodi_visitati
	    archi = collect(edges(wg))
		 
		##inizio, la distanza del nodo iniziale da sè stesso è ovviamente zero
	    pq[nodoIniziale] = 0
		
	    while !isempty(pq)
			
			colorenodi = copy(colorenodi_steps[end])
	        nodoAttuale,distanza = dequeue_pair!(pq) #rimuovo il minimo dalla PQ e ne 		tengo il valore di priorità, ossia la distanza dall'origine in quella che 		era la miglior stima
			#coloro il nodo che sto visitando e l'arco entrante come appartenenti alla soluzione
			colorenodi[nodoAttuale] = colore_nodi_visitati
			colorearchi = copy(colorearchi_steps[end])
			for i in 1:ne(wg)
				if (archi[i].dst == nodoAttuale || archi[i].src == nodoAttuale) && colorearchi[i] == colore_archi_visitati
					colorearchi[i] = colore_archi_sol
				end
			end
					
	        for v in neighbors(wg,nodoAttuale)
	            pesoValutato = distanza + wg.weights[nodoAttuale,v]
				#se il vicino del nodo non è ancora stato visitato confronto la sua distanza attuale con quella trovata in pesoValutato
				if colorenodi[v] != colore_nodi_visitati
	            #se è ancora inf -> metto in pq con pesovalutato come priorità,lo 				coloro come appartentente alla frontiera e aggiorno la distanza
					if pq[v] == typemax(Float64) 
	                    pq[v]= pesoValutato
						colorenodi[v]= colore_nodi_visti
	                    add_edge!(T,nodoAttuale,v)
						#rendo nodoAttuale padre di v in T
						for i in 1:ne(wg)
							if Edge(nodoAttuale,v) == archi[i] || Edge(v,nodoAttuale) == archi[i]
								colorearchi[i] = colore_archi_visitati
							end
						end
				#se il peso appena visto non è minore di quello precedentemente stimato allora scarto il nodo
					elseif pesoValutato >= pq[v]
						for i in 1:ne(wg)
							if Edge(nodoAttuale,v) == archi[i] || Edge(v,nodoAttuale) == archi[i]
								colorearchi[i] = colore_archi_scartati
							end
						end
				#se il peso è minore dell'attuale aggiorno distanza e pq con i nuovi valori, scartando gli altri nodi entranti in v che erano precedentemente colorati come appartententi alla frontiera	
					elseif pesoValutato < pq[v] 
	                    pq[v] = pesoValutato 
						for i in 1:ne(wg)
							if (archi[i].dst == v || archi[i].src == v) && colorearchi[i] == colore_archi_visitati
								colorearchi[i] = colore_archi_scartati
							end
							if Edge(nodoAttuale,v) == archi[i] || Edge(v,nodoAttuale) == archi[i]
								colorearchi[i] = colore_archi_visitati
							end
						end
						#aggiorno T rendo il nodoAttuale padre di v 
	                    for verticeVicinoInT in neighbors(T,v)
	                        rem_edge!(T,verticeVicinoInT,v)
	                    end 
	                    add_edge!(T,nodoAttuale,v)    
		            end

		        end	            
	        end
			#inserisco le colorazioni dei nodi attuali nel mio array per l'illustrazione del procedimento step by step
			push!(colorenodi_steps, colorenodi)
			push!(colorearchi_steps, colorearchi)	
		end
		#riporto i pesi degli archi di wg a quelli corrispondenti in T
		T = SimpleWeightedGraph(T)
	    for e in edges(T)
	        T.weights[e.src,e.dst] = T.weights[e.dst, e.src] = wg.weights[e.src,e.dst]
	    end
		return T, colorenodi_steps, colorearchi_steps
	end	
end

# ╔═╡ 6a6e0e4e-a716-45ba-a842-9ca0fb025d52
md"""
# Minimum Spanning Tree (MST)

È un problema di **minimizzazione**.

**Definizione:** Sia G un grafo **(*diretto o non diretto*)** **$G(V,E,w)$**, connesso e pesato dove $V$ è l'insieme dei nodi, $E ⊆ V×V$ è l'insieme degli archi e $w(u,v) ∈ \mathbb{R}^+$ sia una funzione peso per $G$.

Uno **Spanning tree** è un albero con queste proprietà: è **connesso**, **aciclico**, **spanning** (copre tutti i nodi del grafo).

**Goal**: un albero $T ⊆ E$, che sia uno spanning tree di $G$, che minimizza il costo di T:

$C(T) = \sum_{e \in T} \ w(e)$


Gli algoritmi che risolvono il problema dell'MST sono **Prim**, **Kruskal** e **Reverse Delete**; tutti e tre utilizzano un approccio **greedy**.
"""

# ╔═╡ be30acc4-8f1c-4370-854e-ce972bd67587
	md"""

	### Prim

	"""

# ╔═╡ bbdd3aa7-0118-43ee-b12d-caa47084a33f
begin	
	function Prim(wg::SimpleWeightedGraph)
		#init con randomizzazione del nodo iniziale
		nodoIniziale = rand(1:nv(wg))
		T = SimpleGraph(nv(wg)) 
		pesoTot = 0 
		colorearchi_steps = [fill(colore_archi_da_visitare,ne(wg))]
		colorenodi_steps = [fill(colore_archi_da_visitare,nv(wg))]
		colorenodi_steps[1][nodoIniziale] = colore_nodi_visitati
	    archi = collect(edges(wg))

		#inizio
		pq = PriorityQueue(1:nv(wg) .=> typemax(Float64))
		pq[nodoIniziale] = 0

		while !isempty(pq)
			
			colorenodi = copy(colorenodi_steps[end])
	        nodoAttuale = dequeue!(pq) #minimo dalla PQ
			#coloro il nodo che sto visitando, e l'arco entrante come appartenenti alla soluzione
			colorenodi[nodoAttuale] = colore_nodi_visitati
			colorearchi = copy(colorearchi_steps[end])
			for i in 1:ne(wg)
				if (archi[i].dst == nodoAttuale || archi[i].src == nodoAttuale) && colorearchi[i] == colore_archi_visitati
					colorearchi[i] = colore_archi_sol
				end
			end
			
			for v in neighbors(wg,nodoAttuale)
				#guardo ogni nodo che non è ancora stato visitato
				if colorenodi[v] != colore_nodi_visitati
					#se il nodo non era stato precedentemente considerato aggiorno il suo valore di distanza
					if pq[v] == typemax(Float64) 
	                	pq[v] = wg.weights[nodoAttuale,v]
						colorenodi[v]= colore_nodi_visti
						#rendo v figlio di nodoAttuale in T
	                    add_edge!(T,nodoAttuale,v)
						for i in 1:ne(wg)
							if Edge(nodoAttuale,v) == archi[i] || Edge(v,nodoAttuale) == archi[i]
								colorearchi[i] = colore_archi_visitati
							end
						end
					#se il peso dell'arco considerato non è minore di quello attualmente nella priority queue scarto l'arco
					elseif wg.weights[nodoAttuale,v] >= pq[v]
						for i in 1:ne(wg)
							if Edge(nodoAttuale,v) == archi[i] || Edge(v,nodoAttuale) == archi[i]
								colorearchi[i] = colore_archi_scartati
							end
						end
					#se l'arco considerato è di peso minore di quello precedentemente considerato lo marco come in frontiera, e scarto il nodo precedente.
					elseif pq[v] > wg.weights[nodoAttuale,v]
						pq[v] = wg.weights[nodoAttuale,v]
						for i in 1:ne(wg)
							if (archi[i].dst == v || archi[i].src == v) && colorearchi[i] == colore_archi_visitati
								colorearchi[i] = colore_archi_scartati
							end
							if Edge(nodoAttuale,v) == archi[i] || Edge(v,nodoAttuale) == archi[i]
								colorearchi[i] = colore_archi_visitati
							end
						end
						#poi modifico T per avere nodoAttuale padre di v
	                    for verticeVicinoInT in neighbors(T,v)
	                        rem_edge!(T,verticeVicinoInT,v)
	                    end 
	                    add_edge!(T,nodoAttuale,v) 
						
					end
				end
			end
			#inserisco le modifiche appena fatte nell'array per i passi dell'algoritmo
			push!(colorenodi_steps, colorenodi)
			push!(colorearchi_steps, colorearchi)	
		end
		#assegno i pesi agli archi di T, come i corrispondenti pesi in wg
		T = SimpleWeightedGraph(T)
	    for e in edges(T)
	        T.weights[e.src,e.dst] = T.weights[e.dst, e.src] = wg.weights[e.src,e.dst]
	    	pesoTot += wg.weights[e.src,e.dst]
		end
		return T, colorenodi_steps, colorearchi_steps, pesoTot
	end
end

# ╔═╡ 345a6354-9ea7-4ccf-90c0-86afeba0e745
begin
	tDj, colorinodiDJ,coloriarchiDJ = Dijkstra(wg,1)
	tPm, colorinodiPM,coloriarchiPM, pesoTot = Prim(wg)
end

# ╔═╡ 261235c8-e71d-48f3-b4c5-8929b590abfb
begin
	md"""
	Dijkstra step: $(@bind t1 Slider(1:length(coloriarchiDJ), show_value=true))
	"""
end

# ╔═╡ 30b6b783-c0a6-4f3e-97e8-2b53de775797
md""" 

##### Prim(G)


E' un algoritmo di visita che, partendo da un nodo iniziale 
u (scelto arbitrariamente) esamina tutti i nodi del grafo.


Ad ogni iterazione, partendo da un nodo v, visita un nuovo nodo w e inserisce l'arco (v,w) dentro un insieme. Questo insieme conterrà la soluzione ottima.
Il prossimo nodo da visitare (e quindi l'arco da inserire nell'insieme) viene scelto tramite un apposito criterio: **l'arco (v,w) deve essere l'arco con peso minimo che parte da v e va verso un nodo non ancora esplorato.** Il tutto viene gestito servendosi di una Coda con priorità.


Questo processo viene ripetuto fin quando l'insieme contiene tutti i vertici del grafo.

"""

# ╔═╡ 4be09b3a-eae5-4bac-a4d2-ca445a8d277f
md"""

##### Implementazione

L'algoritmo inizia con la scelta randomica di un nodo del grafo, che sarà il nodo sorgente.
Viene inizializzata anche una coda di priorità con tutti i valori a infinito e un grafo T che sarà il nostro MST.

A questo punto:
- estraggo il minimo u dalla coda di priorità
- tra tutti i nodi w adiacenti a u, scelgo l'arco (u,w) con costo minimo e con w non contenuto in T
- inserisco w in T

Il tutto viene ripetuto fintantoché la coda di priorità non è vuota.




"""


# ╔═╡ c9603a2a-4d7d-4002-acf4-d4c894e82ea2
md"""

##### Costo

L'analisi del costo temporale coincide con quella dell'algoritmo di Dijkstra. 

Il costo risultate, utilizzando un **Heap di Fibonacci** pertanto è $\mathcal{O}(m+ n\log{}n)$

"""

# ╔═╡ 821f0204-8d23-4f7c-a58b-aec5f6237e14
begin
	md"""
	Prim step: $(@bind t2 Slider(1:length(coloriarchiPM), show_value=true))
	"""
end

# ╔═╡ 05c347fe-4e41-49d8-a948-403b0257683b
md"""
**il peso totale dell'MST derivante dall'esecuzione dell'algoritmo di Prim sul grafo wg è $pesoTot**
"""

# ╔═╡ 45b8e413-e7a1-4453-bf39-16347c0693e0
md"""
### Union-Find
---
Nel problema Union-Find l' obiettivo è mantenere una collezione di insiemi disgiunti contenenti elementi distinti  di un insieme permettendo sequenze di operazioni del seguente tipo:

–makeSet(x)= crea il nuovo insieme x={x}.

–union(A,B)= unisce gli insiemi A e B in un unico insieme, di nome A, e distrugge i vecchi insiemi A e B(si suppone di accedere direttamente agli insiemi A,B).

–find(x)= restituisce il nome dell’insieme contenente l’elemento x (si suppone di accedere direttamenteall’elemento x).

"""

# ╔═╡ 51ca6f22-021d-4c29-a339-2aa91825963e
md"""
#### Costo
---

find e makeSet richiedono solo tempo $O({1})$

Per quanto riguarda il tempo per le operazioni di union, 
su un singolo nodo il costo speso è $O({\log n})$ mentre in totale, il costo è 
$O({n \log n})$.

Se eseguiamo m find, n makeSet, e le al più n-1 union, 

L’intera sequenza di operazioni costa
$O(m+n+n \log n)=O(m+n \log n)$

"""

# ╔═╡ 4a758f2f-23f5-4e3c-be83-4d03cdcfdbef
begin 
	mutable struct UnionFind
    	sizes :: Vector
    	parents :: Vector
	
		UnionFind(N :: Int) = N <= 0 ? error("il numero di nodi è negativo") : new(Vector{Int}(undef, Int(N)), Vector{Int}(undef, Int(N)))
  
	end
	
	function makeset(uf::UnionFind,e::Int)
		
		#ogni elemento è di dimensione 1
		uf.sizes[e]=1
		#indice di se stesso
		uf.parents[e]=e
		
	end
	
	#restituisce la radice del nodo
	function find(uf :: UnionFind, e :: Int)
		
    	if e > length(uf.parents) || e <= 0
        	throw(BoundsError())
    	end
		
  
    	return uf.parents[e]
	end
	
	#funzione che unisce i due insiemi in un unico 
	function union(uf::UnionFind,a::Int,b::Int)
		A = find(uf, a)
    	B = find(uf, b)

   	#se questi due elementi sono uguali vuol dire che sono già nello stesso insieme
    	if A == B
        	return
		#uniamo gli elementi dell'insieme più piccolo in quello piu grande	
		elseif uf.sizes[A] < uf.sizes[B]
			for i in 1:length(uf.sizes)
				if uf.parents[i]==A
					uf.parents[i]=B
					uf.sizes[A]-=1
					uf.sizes[B]+=1
				end
			end

		else
			for i in 1:length(uf.sizes)
				if uf.parents[i]==B
					uf.parents[i]=A
					uf.sizes[B]-=1
					uf.sizes[A]+=1
				end
			end		

    	end
	end
end

# ╔═╡ 8963d2c6-3a8e-44c4-a281-4ab943043306
md"""
### Kruskal(G)
---

L'algoritmo di Kruskal usa un approccio greedy per trovare un $minumum$ $spanning$ $tree$ (**MST**) di un grafo $G$ non orientato e con gli archi con costi non negativi.

Ordina gli archi secondo costi crescenti e costruisce un insieme ottimo di
archi T scegliendo di volta in volta un arco di peso minimo che non
forma cicli con gli archi già scelti



"""

# ╔═╡ 80593b75-3069-4ca5-a1c3-120bb946b35b
md"""
#### Implementazione

L'algoritmo è implementato utilizzando la struttura dati Union-Find e la libreria *SimpleWeightedGraphs* per rappresentare il grafo pesato G, che nel nostro caso è indiretto e connesso.

Viene gestita una partizione W = {$W_{1}$,$W_{2}$, . . . , $W_{k}$ }  di V,
insieme dei nodi del grafo, in cui ogni $W_{i}$ rappresenta un insieme di nodi
per cui è stato scelto un insieme di archi che li collega.
Inizialmente, T = 0 e W = {{1}, {2}, . . . , {n}}, poichè nessun arco è
stato scelto e, quindi, nessun nodo è stato collegato.

Alla prima iterazione viene scelto il nodo (u, v) di peso minimo; questo
viene posto in T (T è vuoto e quindi l’inserimento di (u, v) non può
formare cicli) e gli insiemi {u} e {v} vengono sostituiti con l’insieme
{u, v}

Alla generica iterazione i, esaminiamo l’arco (x, y) con i-esimo costo che
viene aggiunto alla soluzione T solo se i nodi x e y non appartengono
allo stesso insieme della partizione W (cioè se l’arco non forma cicli con
gli archi inseriti in precedenza)
In questo caso, dopo aver inserito l’arco (x, y) in T, si sostituiscono nella
partizione W gli insiemi (distinti) contenenti x e y con la loro unione.

"""

# ╔═╡ e7db907d-856c-4890-958d-4caa12b7b268
md"""
#### Costo
---

L’intera sequenza di operazioni della struttura dati Union-Find costa O({m}+{n}\log {n})$

Quindi il costo totale sarà uguale a $O(m \log n + n \log n + m)= O(m \log n)$.

"""

# ╔═╡ 44dca619-68d8-4cd7-a5d8-5f281c48ebe7
function Kruskal(G :: SimpleWeightedGraph) :: Tuple{SimpleWeightedGraph, Vector}

	T = SimpleWeightedGraph(nv(G))
	uf = UnionFind(nv(G))
	for i in 1:nv(G)
		makeset(uf,i)
	end
	#indici degli archi ordinati
	perm_archi_ord = sortperm(collect(edges(G)), by=weight, rev=true)
	archi = collect(edges(G))
	
	#array che conterrà i colori degli archi ad ogni passo
	colori_archi_step_by_step = []
	
	while length(perm_archi_ord) != 0
		#prendo il set di colori usati nel passo precedente
		if length(colori_archi_step_by_step) == 0
			colori_archi = [colore_archi_da_visitare for i in 1:ne(G)]
		else
			colori_archi = pop!(colori_archi_step_by_step)
		end

		#estraggo l'indice del primo arco da controllare
		index_e = pop!(perm_archi_ord)
		#coloro l'arco visitato
		colori_archi[index_e] = colore_archi_visitati
		push!(colori_archi_step_by_step, colori_archi)
		colori_archi = copy(colori_archi)

		e = archi[index_e]		
		#inserire l'arco solo se non crea un ciclo t
		if find(uf,e.src) != find(uf,e.dst)
			add_edge!(T, e.src, e.dst, e.weight)
			colori_archi[index_e] = colore_archi_sol
			union(uf,e.src,e.dst)
		else
			colori_archi[index_e] = colore_archi_scartati
		end
		push!(colori_archi_step_by_step, colori_archi)
		
	end

	return T, colori_archi_step_by_step
end

# ╔═╡ 04405d0e-cf04-4a1b-9392-fb6626aeb1fc
t3, c3  = Kruskal(wg)

# ╔═╡ a1d8d616-c4e9-421b-b99a-035531d63764
begin
	md"""
	Kruskal t: $(@bind t7 Slider(1:ne(wg)+1, show_value=true))
	"""
end

# ╔═╡ 97664d09-38f2-4c72-82c2-3a827c80f4e2
md"""
###### Costo soluzione Kruskal : $(sum(weight.(edges(t3)))) 
"""

# ╔═╡ a91b3846-dc50-4173-831a-75a819debb09
md"""
#### Reverse Delete
"""

# ╔═╡ 13904c16-dbab-4425-93d8-2329fc72b39e
md"""
##### ReverseDelete(G)

L'algoritmo Reverse Delete usa un approccio greedy per trovare un $minumum$ $spanning$ $tree$ (**MST**) di un grafo $G$ non orientato e con gli archi con costi non negativi.

A ogni passo elimina l'arco più pesante a meno che non renda il grafo non più connesso.

Più nello specifico l'algoritmo è diviso in due parti:
- La prima dove definisce $T$ come $T$ = $E$ e ordina gli archi in **ordine decrescente** di costo.
- Analizza in ordine ogni arco. **Elimina l'arco a meno che non renda il grafo non più connesso**.

Notiamo che a ogni passo, se abbiamo più archi con lo stesso costo, è indifferente quale viene scelto. Ad un grafo possono corrispondere più MST con lo stesso costo minimo.

La strategia dell'algoritmo Reverse Delete è simile a quella usata dall'algoritmo di Kruskal con la differenza che in Kruskal si inizia con un insieme vuoto e a ogni passo si aggiungono gli archi che appartengono alla soluzione, mentre nel Reverse-Delete si inizia con un insieme composto da tutti gli archi del grafo e a ogni passo si cancellano gli archi che non appartengono alla soluzione.
"""

# ╔═╡ 2fee9c3f-9cb2-41c1-9d3e-6e2713d9286c
md"""
#### Implementazione

L'algoritmo è implementato utilizzando la libreria *SimpleWeightedGraphs* per rappresentare il grafo pesato G, che nel nostro caso è indiretto e connesso.


L'algoritmo ha questa struttura:
- Definisce $T$ come $T$ = $E$.
- Ordina gli archi in ordine decrescente di peso
- per ogni arco $e=(u,v)$:
   - rimuove $e$ da T e verifica se T è ancora connesso:
     - se non lo è più reinserisce $e$ in T.
   
La verificare se il grafo è connesso viene eseguita dalla funzione è_connesso(T), che in pratica è una visita in ampiezza (BFS) modificata che conta il numero di nodi che visita e alla fine li confronta con il numero di nodi di T. Se i nodi visitati sono uguali a |V| significa che T è connesso.
"""

# ╔═╡ 6139ed81-d841-44dd-b49c-ccf37add8d7e
md"""
#### Costo
---

Consideriamo:
  - n = |V|
  - m = |E|

La funzione è_connesso(T) è una BFS con in più un semplice contatore di nodi visitati quindi ha un costo di $O(m + n)$.

Quest'operazione viene ripetuta per m volte (per tutti gli archi di T).
Quindi alla fine il costo per scorrere tutti gli archi e decidere se fanno parte della soluzione o meno ha un costo di $O(m(m + n))$.

Questo costo è asintoticamente inferiore al costo per ordinare gli archi, quindi il costo finale dell'algoritmo è:

$O(m(m + n))$

Possiamo notare che l'algoritmo Reverse Delete ha un costo asintoticamente maggiore rispetto all'algoritmo di Kruskal visto che quello ha un costo di $O(m\log{n})$

"""

# ╔═╡ 6cd54522-2ba7-4983-9a13-899ed308db56
#BFS modificata per vedere se il grafo è connesse
#finita la visita confronta il numero di nodi visitati con i nodi totali di G
#se sono uguali significa che il grafo è connesso quindi ritorna true
#altrimenti ritorna false
function è_connesso(G :: SimpleGraph) :: Bool
	u = vertices(G)[1]
	#SPT = SimpleGraph(nv(G))
	
	ordine_vista_nodi = []

	marcatore_nodi = [false for n=1:nv(G)]
	q1 = Queue{Int}()
	marcatore_nodi[u] = true
	enqueue!(q1, u)
	contatore_nodi_visitati = 1
	
	while !isempty(q1)
		u = dequeue!(q1)

		append!(ordine_vista_nodi, u)
		#println("ordine_vista_nodi",ordine_vista_nodi)
		
		#println("visito:",u)
		#println("outneighbors(",u,"):",outneighbors(G, u))
			
		for v in outneighbors(G, u)
			if !marcatore_nodi[v]
				#println("v:",v)
				enqueue!(q1, v)
				marcatore_nodi[v] = true
				contatore_nodi_visitati += 1
				#add_edge!(SPT,u,v)
			end
		end
		#println("marcatore_nodi:",marcatore_nodi)
		#println("contatore_nodi_visitati:",contatore_nodi_visitati)
	end
	
	if(contatore_nodi_visitati == nv(G))
		return true
	end
	return false
end

# ╔═╡ 4513720a-8b76-4569-9b64-77433b245814
function reverse_delete(G :: SimpleWeightedGraph) :: Tuple{SimpleWeightedGraph, Vector}
	#rem_edge su SimpleWeightedGraph non funziona
	T = SimpleGraph(G)
	#indici degli archi ordinati
	perm_archi_ord = sortperm(collect(edges(G)), by=weight)
	archi = collect(edges(G))
	
	#array che conterrà i colori degli archi ad ogni passo
	colori_archi_step_by_step = []
	
	while length(perm_archi_ord) != 0
		#prendo il set di colori usati nel passo precedente
		if length(colori_archi_step_by_step) == 0
			colori_archi = [colore_archi_da_visitare for i in 1:ne(G)]
		else
			colori_archi = pop!(colori_archi_step_by_step)
		end

		#estraggo l'indice del primo arco da controllare
		index_e = pop!(perm_archi_ord)
		#coloro l'arco visitato
		colori_archi[index_e] = colore_archi_visitati
		push!(colori_archi_step_by_step, colori_archi)
		colori_archi = copy(colori_archi)

		e = archi[index_e]
		rem_edge!(T, e.src, e.dst)
		colori_archi[index_e] = colore_archi_scartati
		#dopo aver rimosso l'arco verifco se T è ancora connesso
		if !è_connesso(T)
			add_edge!(T, e.src, e.dst)
			colori_archi[index_e] = colore_archi_sol
		end
		push!(colori_archi_step_by_step, colori_archi)
		
	end

	#converto la soluzione T da SimpleGraph a SimpleWeightedGraph
	T = SimpleWeightedGraph(T)
	for e in edges(T)
		T.weights[e.src,e.dst] = T.weights[e.dst, e.src] = G.weights[e.src, e.dst]
	end
	
	return T, colori_archi_step_by_step
end

# ╔═╡ ac89eba5-8c25-4613-97f1-1b1ca92519b9
T₁, c₁ = reverse_delete(wg)


# ╔═╡ aa34d4fc-5fd6-408d-8892-393fea7646f0
begin
	md"""
	Reverse Delete step: $(@bind t₁ Slider(1:ne(wg)+1, show_value=true))
	"""
end

# ╔═╡ 102ebee3-ae6c-4b51-8e9c-86963db88a94
md"""
###### Costo soluzione Reverse Delete : $(sum(weight.(edges(T₁)))) 
"""

# ╔═╡ 48bb0d56-8f05-4d72-af42-a2ff311ca26c
begin
	pkr = tPm == t3 == T₁
	pk = tPm == t3
	pr = tPm == T₁
	kr = T₁ == t3
md"""
**Osservazione**: Per ogni grafo possono corrispondere più spanning tree con lo stesso costo minimo.

Nel nostro caso possiamo notare che: $(if pkr
	"Tutti e tre gli MST sono uguali."
elseif pk
	"L'MST trovato da Prim e Kruscal è uguale, mentre quello di Reveser Delete ha degli archi diversi."
elseif pr
	"L'MST trovato da Prim e Reveser Delete è uguale, mentre quello di Kruskal ha degli archi diversi."
elseif kr
	"L'MST trovato da kruskal e Reveser Delete è uguale, mentre quello di Prim ha degli archi diversi."
else
	"Tutti e tre gli MST hanno degli archi diversi."
end)
"""
end

# ╔═╡ 0d79776e-9c91-4716-a075-59175e423fbc
md"""
**Funzioni di supporto in comune**

plot_step_by_step : traccia passo passo dell'esecuzione dell'algoritmo

show_sol_plot : plot del grafo derivante dall'esecuzione dell'algoritmo
"""

# ╔═╡ 4d8f2bad-8fc8-4cec-9fb7-d0d8d3a5f5f0
function plot_step_by_step(G :: SimpleWeightedGraph, t :: Int;
	colori_archi_step_by_step = [] :: Vector, colori_nodi_step_by_step = [] :: Vector)
	if length(colori_archi_step_by_step) == 0 && length(colori_nodi_step_by_step) > 0
		p = gplot(G, nodelabel=nodelabel, locs_x, locs_y, edgelabel=weights, nodefillc=nodecolor[colori_nodi_step_by_step[t]],edgelabelc=colorant"black",EDGELABELSIZE=5)
	elseif length(colori_archi_step_by_step) > 0 && length(colori_nodi_step_by_step) == 0
		p = gplot(G, nodelabel=nodelabel, locs_x, locs_y, edgelabel=weights, edgestrokec=nodecolor[colori_archi_step_by_step[t]],edgelabelc=colorant"black",EDGELABELSIZE=5)
	else
		p = gplot(G, nodelabel=nodelabel, locs_x, locs_y, edgelabel=weights, edgestrokec=nodecolor[colori_archi_step_by_step[t]], nodefillc=nodecolor[colori_nodi_step_by_step[t]],edgelabelc=colorant"black",EDGELABELSIZE=5)
	end
	output = compose(p,(context(), rectangle(-10,-10,20,20), fill("white"), Compose.stroke("black")))
end

# ╔═╡ 09a0ee47-913e-4484-baf9-deadd6798c31
begin
	plot_step_by_step(wg, t1, colori_archi_step_by_step = coloriarchiDJ, colori_nodi_step_by_step = colorinodiDJ)
end

# ╔═╡ 54e4b655-c3b6-4d64-92f8-8d594390ace6
begin
	plot_step_by_step(wg,t2,colori_archi_step_by_step = coloriarchiPM, colori_nodi_step_by_step = colorinodiPM)
end

# ╔═╡ 9f16efb2-f611-481e-9e95-54f32121d4c1

plot_step_by_step(wg, t7, colori_archi_step_by_step = c3)




# ╔═╡ fc82e9bb-7518-4fd5-a7c9-b5d94b9adc38
plot_step_by_step(wg, t₁, colori_archi_step_by_step = c₁)


# ╔═╡ 0680f459-2edb-4c4a-86b1-02d7084eda53
function show_sol_plot(G :: SimpleWeightedGraph)
    weights = weight.(collect(edges(G)))
    p = gplot(G, nodelabel=nodelabel, locs_x, locs_y, edgelabel=weights,edgelabelc=colorant"black",EDGELABELSIZE=5)
    output = compose(p, (context(), rectangle(-10,-10,20,20), fill("white"), Compose.stroke("black")))
end

# ╔═╡ 2521a152-e145-4c77-a496-92ac750211cc
show_sol_plot(tDj)

# ╔═╡ ff2aaa2d-1c34-45c8-8efb-60c88072727a
show_sol_plot(tPm)

# ╔═╡ b4b7d8e0-202f-4673-af58-6966301b5ed9
show_sol_plot(t3)

# ╔═╡ 388dcadb-05a8-44ad-8827-88f52f738117
show_sol_plot(T₁)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
Compose = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
DataStructures = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
GraphPlot = "a2cc645c-3eea-5389-862e-a155d0052231"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
SimpleWeightedGraphs = "47aef6b3-ad0c-573a-a1e2-d07658019622"

[compat]
Colors = "~0.12.8"
Compose = "~0.9.4"
DataStructures = "~0.18.13"
GraphPlot = "~0.5.2"
Graphs = "~1.7.4"
PlutoUI = "~0.7.43"
SimpleWeightedGraphs = "~1.2.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "3ca828fe1b75fa84b021a7860bd039eaea84d2f2"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.3.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Compose]]
deps = ["Base64", "Colors", "DataStructures", "Dates", "IterTools", "JSON", "LinearAlgebra", "Measures", "Printf", "Random", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "d853e57661ba3a57abcdaa201f4c9917a93487a2"
uuid = "a81c6b42-2e10-5240-aca2-a61377ecd94b"
version = "0.9.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.GraphPlot]]
deps = ["ArnoldiMethod", "ColorTypes", "Colors", "Compose", "DelimitedFiles", "Graphs", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "5cd479730a0cb01f880eff119e9803c13f214cab"
uuid = "a2cc645c-3eea-5389-862e-a155d0052231"
version = "0.5.2"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "ba2d094a88b6b287bd25cfa86f301e7693ffae2f"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "595c0b811cf2bab8b0849a70d9bd6379cc1cfb52"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.4.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "2777a5c2c91b3145f5aa75b61bb4c2eb38797136"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.43"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays", "Test"]
git-tree-sha1 = "a6f404cc44d3d3b28c793ec0eb59af709d827e4e"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.2.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "f86b3a049e5d05227b10e15dbb315c5b90f14988"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.9"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─b820d04c-c209-47dc-badf-5087098e3476
# ╟─db7f3e0b-8ee6-4488-a0bf-a892158a58e5
# ╟─34812883-58e8-4e39-a7f4-2dbb36baa4e1
# ╟─58ca638a-af7a-4fd6-975d-b725d147a107
# ╟─a8df7f90-40d3-11ed-2831-fb39b1be2aea
# ╟─f14f9f40-ee82-49d7-b16f-a9920fae9cc6
# ╟─e55bf473-41e0-4459-a442-b54749cebfb5
# ╟─88d329e1-c4f5-49e9-8447-1f5c9892fd5c
# ╟─04cb9eff-1da0-4a42-9c38-5e551146112c
# ╟─e7d0b91c-7e2c-45fa-9407-f39924312acd
# ╠═0f112506-d940-4e90-8f4c-4fc2cb6f8ca0
# ╟─e21a230e-4ee8-4da5-abbf-61e56e1f5c7e
# ╠═f5a1db0e-fe70-46f2-bed2-b5e70c043f7e
# ╟─345a6354-9ea7-4ccf-90c0-86afeba0e745
# ╟─db6cecb4-f037-4c60-ba8e-1c35beb23b27
# ╟─9b2c7452-c922-495c-998a-cbdcbbe70b9f
# ╟─18d76fcc-f805-4426-95e3-2792a79914dd
# ╟─261235c8-e71d-48f3-b4c5-8929b590abfb
# ╟─09a0ee47-913e-4484-baf9-deadd6798c31
# ╟─2521a152-e145-4c77-a496-92ac750211cc
# ╟─6a6e0e4e-a716-45ba-a842-9ca0fb025d52
# ╟─be30acc4-8f1c-4370-854e-ce972bd67587
# ╟─bbdd3aa7-0118-43ee-b12d-caa47084a33f
# ╟─30b6b783-c0a6-4f3e-97e8-2b53de775797
# ╟─4be09b3a-eae5-4bac-a4d2-ca445a8d277f
# ╠═c9603a2a-4d7d-4002-acf4-d4c894e82ea2
# ╟─821f0204-8d23-4f7c-a58b-aec5f6237e14
# ╟─54e4b655-c3b6-4d64-92f8-8d594390ace6
# ╟─ff2aaa2d-1c34-45c8-8efb-60c88072727a
# ╟─05c347fe-4e41-49d8-a948-403b0257683b
# ╟─45b8e413-e7a1-4453-bf39-16347c0693e0
# ╟─51ca6f22-021d-4c29-a339-2aa91825963e
# ╟─4a758f2f-23f5-4e3c-be83-4d03cdcfdbef
# ╟─8963d2c6-3a8e-44c4-a281-4ab943043306
# ╟─80593b75-3069-4ca5-a1c3-120bb946b35b
# ╟─e7db907d-856c-4890-958d-4caa12b7b268
# ╟─44dca619-68d8-4cd7-a5d8-5f281c48ebe7
# ╟─04405d0e-cf04-4a1b-9392-fb6626aeb1fc
# ╟─a1d8d616-c4e9-421b-b99a-035531d63764
# ╟─9f16efb2-f611-481e-9e95-54f32121d4c1
# ╟─b4b7d8e0-202f-4673-af58-6966301b5ed9
# ╟─97664d09-38f2-4c72-82c2-3a827c80f4e2
# ╟─a91b3846-dc50-4173-831a-75a819debb09
# ╟─13904c16-dbab-4425-93d8-2329fc72b39e
# ╟─2fee9c3f-9cb2-41c1-9d3e-6e2713d9286c
# ╠═6139ed81-d841-44dd-b49c-ccf37add8d7e
# ╟─6cd54522-2ba7-4983-9a13-899ed308db56
# ╟─4513720a-8b76-4569-9b64-77433b245814
# ╟─ac89eba5-8c25-4613-97f1-1b1ca92519b9
# ╟─aa34d4fc-5fd6-408d-8892-393fea7646f0
# ╟─fc82e9bb-7518-4fd5-a7c9-b5d94b9adc38
# ╟─388dcadb-05a8-44ad-8827-88f52f738117
# ╟─102ebee3-ae6c-4b51-8e9c-86963db88a94
# ╠═48bb0d56-8f05-4d72-af42-a2ff311ca26c
# ╟─0d79776e-9c91-4716-a075-59175e423fbc
# ╟─4d8f2bad-8fc8-4cec-9fb7-d0d8d3a5f5f0
# ╟─0680f459-2edb-4c4a-86b1-02d7084eda53
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
