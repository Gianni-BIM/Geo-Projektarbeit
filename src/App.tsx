import { useState, useMemo, useCallback } from 'react';
import { soilData } from './data/soilData';
import { treeStructure, isPointInNode } from './data/decisionTreeModel';
import SoilMap from './components/SoilMap';
import DecisionTree from './components/DecisionTree';
import ScientificCharts from './components/ScientificCharts';
import SoilDataTable from './components/SoilDataTable';
import SHIHistogram from './components/SHIHistogram';
import ModelReport from './components/ModelReport';
import { TreeNode } from './types';
import { Shield, Database, Sprout, BarChart2 } from 'lucide-react';

const findNodeById = (node: TreeNode, id: string): TreeNode | null => {
  if (node.id === id) return node;
  if (node.children) {
    const left = findNodeById(node.children[0], id);
    if (left) return left;
    const right = findNodeById(node.children[1], id);
    if (right) return right;
  }
  return null;
};

export default function App() {
  const [selectedNodeId, setSelectedNodeId] = useState<string>('root');
  const [colorByMode, setColorByMode] = useState<'SHI' | 'land_use' | 'land_cover' | 'climate_name'>('SHI');
  const [selectedPointId, setSelectedPointId] = useState<number | null>(null);

  // 1. Dynamic filtration on raw list based on Decision Tree Node Selection
  const filteredData = useMemo(() => {
    return soilData.filter((point) => {
      // Check active tree node selection
      return isPointInNode(point, selectedNodeId);
    });
  }, [selectedNodeId]);

  // Handle dynamic map markers selection callback
  const handleSelectPoint = useCallback((pointId: number | null) => {
    setSelectedPointId(pointId);
  }, []);

  // 2. Calculations of statistics for currently filtered subset
  const filteredStats = useMemo(() => {
    const list = filteredData.map(p => p.SHI).sort((a, b) => a - b);
    const count = list.length;
    
    if (count === 0) return { mean: 0, median: 0, min: 0, max: 0 };
    
    const sum = list.reduce((acc, v) => acc + v, 0);
    const mean = sum / count;
    
    const mid = Math.floor(count / 2);
    const median = count % 2 !== 0 ? list[mid] : (list[mid - 1] + list[mid]) / 2;
    
    return {
      mean,
      median,
      min: list[0],
      max: list[count - 1],
    };
  }, [filteredData]);

  const activeNodeDetails = useMemo(() => {
    return findNodeById(treeStructure, selectedNodeId) || treeStructure;
  }, [selectedNodeId]);

  return (
    <div className="min-h-screen bg-[#fafaf9] text-slate-800 font-sans pb-12 transition-colors duration-150">
      
      {/* 1. Header Navigation brand bar */}
      <header className="bg-white border-b border-slate-200 sticky top-0 z-40 select-none shadow-xs">
        <div className="max-w-[1580px] mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-indigo-600 rounded-xl flex items-center justify-center text-white shadow-md shadow-indigo-100">
              <Shield className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-base font-extrabold text-slate-900 tracking-tight leading-none flex items-center gap-1.5">
                Soil Health Random Forest Explorer
                <span className="text-[10px] font-bold bg-indigo-50 border border-indigo-100/60 text-indigo-700 px-2 py-0.5 rounded-full font-mono uppercase">
                  LUCAS-EU
                </span>
              </h1>
              <p className="text-[10px] text-slate-400 mt-0.5 font-medium">
                Schnittstelle zur interaktiven Entscheidungsunterstützung & Modellgutachten
              </p>
            </div>
          </div>

          {/* Soil Sprout Health Badge (Soil Health themed status badge replacing old calculation indicator) */}
          <div className="flex items-center gap-2.5 bg-emerald-50 border border-emerald-150/40 p-1.5 px-3 rounded-2xl select-none shadow-xs">
            <div className="bg-emerald-600 p-1 rounded-lg text-white">
              <Sprout className="w-3.5 h-3.5" />
            </div>
            <div className="text-left">
              <div className="text-[8px] font-extrabold text-emerald-800 uppercase tracking-wider leading-none">Boden-Status</div>
              <div className="text-[10px] font-black text-emerald-950 leading-none mt-0.5">Aktiv Geladen</div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Grid-driven Content block */}
      <main className="max-w-[1580px] mx-auto px-4 sm:px-6 lg:px-8 mt-6 space-y-6">
        
        {/* UPPER CONTROLS & DYNAMIC BENCHMARKS CARDS */}
        <section className="bg-white border border-slate-200 rounded-3xl p-4 shadow-sm space-y-4">
          
          {/* Controls Bar */}
          <div className="flex items-center justify-between pb-1 flex-wrap gap-3 select-none border-b border-slate-100 pb-3">
            <div className="flex items-center gap-2.5 flex-wrap">
              <span className="text-[9.5px] text-slate-400 font-extrabold uppercase tracking-wider font-sans">
                Karten-Einfärbung steuern:
              </span>
              <div className="flex bg-slate-100/80 p-0.5 rounded-xl border border-slate-200/50">
                {(['SHI', 'land_cover', 'land_use', 'climate_name'] as const).map((mode) => (
                  <button
                    key={mode}
                    onClick={() => setColorByMode(mode)}
                    className={`cursor-pointer px-3 py-1 rounded-lg text-[10px] font-extrabold transition-all ${
                      colorByMode === mode ? 'bg-white text-slate-900 shadow-xs border border-slate-200/30 font-semibold' : 'text-slate-500 hover:text-slate-700'
                    }`}
                  >
                    {mode === 'SHI' ? '🌈 SHI Index' : (mode === 'land_cover' ? '🌱 Bedeckung' : (mode === 'land_use' ? '🚜 Nutzung' : '🌍 Klimatyp'))}
                  </button>
                ))}
              </div>
            </div>
            
            <div className="text-[10px] text-slate-400 italic">
              Klicke auf beliebige Ast-Knoten, um Karte, Histogramm & Tabelle simultan zu filtern.
            </div>
          </div>

          {/* DYNAMIC METRIC BENCHMARK CARDS */}
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            
            {/* 1. Visibles Count */}
            <div className="bg-slate-50 hover:bg-slate-100/50 border border-slate-150 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block">Sichtbare Proben</span>
              <div className="text-xl font-black text-slate-800 font-mono tracking-tight leading-none mt-1">
                {filteredData.length.toLocaleString('de-DE')}
              </div>
              <span className="text-[9px] text-slate-450 block mt-1 leading-tight">von {soilData.length.toLocaleString('de-DE')} Gesamtstellen</span>
            </div>

            {/* 2. Mean SHI */}
            <div className="bg-slate-50 hover:bg-slate-100/50 border border-slate-150 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block text-teal-850">Ø Bodengüte (SHI)</span>
              <div className="text-xl font-black text-teal-700 font-mono tracking-tight leading-none mt-1">
                {filteredStats.mean > 0 ? filteredStats.mean.toFixed(2) : '0.00'}
              </div>
              <span className="text-[9px] text-slate-450 block mt-1 leading-tight">Aktueller Mittelwert</span>
            </div>

            {/* 3. Median SHI */}
            <div className="bg-slate-50 hover:bg-slate-100/50 border border-slate-150 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block">Median SHI</span>
              <div className="text-xl font-black text-slate-800 font-mono tracking-tight leading-none mt-1">
                {filteredStats.median > 0 ? filteredStats.median.toFixed(2) : '0.00'}
              </div>
              <span className="text-[9px] text-slate-450 block mt-1 leading-tight">Mittlerer Zentralwert</span>
            </div>

            {/* 4. Range of SHI */}
            <div className="bg-slate-50 hover:bg-slate-100/50 border border-slate-150 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block select-none">Bodenbereich (Range)</span>
              <div className="text-[14.5px] font-black text-slate-800 font-mono tracking-tight leading-none mt-1.5 mb-0.5 truncate" title={`${filteredStats.min.toFixed(2)}–${filteredStats.max.toFixed(2)}`}>
                {filteredStats.mean > 0 ? `${filteredStats.min.toFixed(2)} – ${filteredStats.max.toFixed(2)}` : '0.00'}
              </div>
              <span className="text-[9px] text-slate-450 block mt-1 leading-normal select-none">Min bis Max Güteskala</span>
            </div>

            {/* 5. Out Of Bag R2 Score */}
            <div className="bg-slate-50 hover:bg-indigo-50/20 border border-indigo-100 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-indigo-500 font-extrabold uppercase tracking-wider block">OOB R² Bestimmtheit</span>
              <div className="text-xl font-black text-indigo-700 font-mono tracking-tight leading-none mt-1">
                0.401
              </div>
              <span className="text-[9px] text-indigo-400 block mt-1 leading-tight">Gesamtmodell Güteklasse</span>
            </div>

            {/* 6. Out Of Bag RMSE Score */}
            <div className="bg-slate-50 hover:bg-slate-100/50 border border-slate-150 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block text-rose-800">OOB RMSE Fehler</span>
              <div className="text-xl font-black text-rose-700 font-mono tracking-tight leading-none mt-1">
                0.347
              </div>
              <span className="text-[9px] text-slate-450 block mt-1 leading-tight">Mittlerer Abweichungsfehler</span>
            </div>

          </div>
        </section>

        {/* ROW 1: SIDE-BY-SIDE DECISION TREE AND SPATIAL GEO-MAP */}
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-stretch">
          
          {/* Left Panel: Decision Tree & Explainer (7/12 layout) */}
          <section id="section-tree" className="xl:col-span-7 flex flex-col">
            <DecisionTree
              tree={treeStructure}
              selectedNodeId={selectedNodeId}
              onSelectNode={setSelectedNodeId}
            />
          </section>

          {/* Right Panel: High Contrast Leaflet interactive Web Map (5/12 layout) */}
          <section className="xl:col-span-5 flex flex-col h-[650px] xl:h-auto min-h-[500px]">
            <SoilMap
              filteredPoints={filteredData}
              colorBy={colorByMode}
              selectedPointId={selectedPointId}
              onSelectPoint={handleSelectPoint}
            />
          </section>

        </div>

        {/* ROW 2: SCIENTIFIC RF VALIDATION GRAPHICS AND DENSITY HISTOGRAM */}
        <section className="grid grid-cols-1 lg:grid-cols-12 gap-6 pb-2">
          
          {/* Left Panel: Spaced thin SHI Histogram (4/12 Grid) */}
          <div className="lg:col-span-4 bg-white border border-slate-200 rounded-3xl p-4 shadow-sm flex flex-col h-full justify-between">
            <div>
              <h4 className="text-[11.5px] font-extrabold text-slate-800 uppercase tracking-wider flex items-center gap-1.5 leading-none">
                <BarChart2 className="w-4 h-4 text-cyan-600 animate-pulse" />
                SHI-Verteilung (Dichte-Histogramm)
              </h4>
              <p className="text-[10px] text-slate-400 mt-1 select-none leading-relaxed">
                Zeigt die Häufigkeitsverteilung des Bodengesundheits-Index (SHI) im aktuell gefilterten Raum mit fein aufgelösten Säulen.
              </p>
            </div>
            
            <div className="flex-1 my-3 flex flex-col justify-center">
              <SHIHistogram shiValues={filteredData.map(d => d.SHI)} />
            </div>
            
            <div className="text-[9.5px] text-slate-400 p-2 bg-slate-50 rounded-xl leading-relaxed text-center select-none font-medium italic">
              Die X-Achse zeigt den SHI-Grad (1.5–4.2), während die Y-Achse die Anzahl Messstationen darstellt.
            </div>
          </div>

          {/* Right Panel: Diagnostic Validation Tabs (8/12 Grid) */}
          <div className="lg:col-span-8 flex flex-col">
            <ScientificCharts filteredPoints={filteredData} />
          </div>

        </section>

        {/* SCIENTIFIC MODEL REPORT & INTERACTIVE TWIN EXPLAINED */}
        <section className="mt-6">
          <ModelReport
            selectedNodeId={selectedNodeId}
            onSelectNode={setSelectedNodeId}
            nodeSamples={activeNodeDetails.sampleCount}
            nodeMeanShi={activeNodeDetails.meanShi}
            nodeRule={activeNodeDetails.rule || ''}
          />
        </section>

        {/* BOTTOM ATTRIBUTE TABLE SECTION */}
        <section id="section-table">
          <SoilDataTable
            data={filteredData}
            selectedPointId={selectedPointId}
            onSelectPoint={handleSelectPoint}
          />
        </section>

      </main>

      {/* Footer credits bar */}
      <footer className="max-w-[1580px] mx-auto px-4 sm:px-6 lg:px-8 mt-12 pt-6 border-t border-slate-200 text-center select-none">
        <p className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider flex items-center justify-center gap-1.5 leading-none">
          <Database className="w-3.5 h-3.5" />
          EU-LUCAS Soil Dataset Explorer & Model Assessor • Bereitgestellt für wissenschaftliche Entscheidungsunterstützung
        </p>
      </footer>

    </div>
  );
}
