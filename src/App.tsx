import { useState, useMemo, useCallback } from 'react';
import { soilData } from './data/soilData';
import { treeStructure, isPointInNode } from './data/decisionTreeModel';
import SoilMap from './components/SoilMap';
import DecisionTree from './components/DecisionTree';
import ScientificCharts from './components/ScientificCharts';
import SoilDataTable from './components/SoilDataTable';
import SHIHistogram from './components/SHIHistogram';
import { TreeNode } from './types';

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
        <div className="max-w-[1580px] mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center">
          <div>
            <h1 className="text-sm font-extrabold text-slate-900 tracking-tight leading-snug max-w-4xl">
          Einfluss von Landnutzung, Klima, Topographie und Ausgangsmaterial auf die Bodengesundheit in Europa </h1>
          </div>
        </div>
      </header>

      {/* Main Grid-driven Content block */}
      <main className="max-w-[1580px] mx-auto px-4 sm:px-6 lg:px-8 mt-6 space-y-6">
        
        {/* UPPER BENCHMARKS CARDS */}
        <section className="bg-white border border-slate-200 rounded-3xl p-4 shadow-sm space-y-4">
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
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block">Ø Bodengüte (SHI)</span>
              <div className="text-xl font-black text-slate-800 font-mono tracking-tight leading-none mt-1">
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
            <div className="bg-slate-50 hover:bg-slate-100/50 border border-slate-150 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block">OOB R² Bestimmtheit</span>
              <div className="text-xl font-black text-slate-800 font-mono tracking-tight leading-none mt-1">
                0.373
              </div>
              <span className="text-[9px] text-slate-450 block mt-1 leading-tight">Gesamtmodell Güteklasse</span>
            </div>

            {/* 6. Out Of Bag RMSE Score */}
            <div className="bg-slate-50 hover:bg-slate-100/50 border border-slate-150 rounded-2xl p-3 px-3.5 transition-colors">
              <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wider block">OOB RMSE Fehler</span>
              <div className="text-xl font-black text-slate-800 font-mono tracking-tight leading-none mt-1">
                0.355
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
              onColorByChange={setColorByMode}
            />
          </section>

        </div>

        {/* ROW 2: SCIENTIFIC RF VALIDATION GRAPHICS AND DENSITY HISTOGRAM */}
        <section className="grid grid-cols-1 lg:grid-cols-12 gap-6 pb-2">
          
          {/* Left Panel: Spaced thin SHI Histogram (4/12 Grid) */}
          <div className="lg:col-span-4 bg-white border border-slate-200 rounded-3xl p-4 shadow-sm flex flex-col h-full justify-between">
            <div>
              <h4 className="text-[11.5px] font-extrabold text-slate-800 uppercase tracking-wider leading-none">
                SHI Häufigkeitsverteilung
              </h4>
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
        <p className="text-[10px] text-slate-300 font-medium uppercase tracking-widest">
          Wissenschaftliches Geoprojekt • Bodengesundheits-Analyse Europa
        </p>
      </footer>

    </div>
  );
}
