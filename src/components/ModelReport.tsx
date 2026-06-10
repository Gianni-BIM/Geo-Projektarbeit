import { Layers, Award, BookOpen, ChevronRight, ShieldAlert } from 'lucide-react';

interface ModelReportProps {
  selectedNodeId: string;
  onSelectNode: (nodeId: string) => void;
  nodeSamples: number;
  nodeMeanShi: number;
  nodeRule: string;
}

// Helper mapper for rules in Wort-Baum mode
const getsWortBaumRule = (nodeId: string, rule: string): string => {
  switch (nodeId) {
    case 'root':
      return 'Niederschlag ≤ 783 mm';
    case 'cool_europe':
      return 'Kein Ackerbau (Anteil ≤ 50%)';
    case 'cool_dry':
      return 'Kein Brachland (Anteil ≤ 50%)';
    case 'cool_wet':
      return 'Außerhalb Steppenklima';
    case 'warm_europe':
      return 'Niederschlag ≤ 1.010 mm';
    case 'warm_agri':
      return 'Ackerbau-Barriere ≤ 50%';
    case 'warm_natural':
      return 'Geländehöhe ≤ 840 m';
    default:
      return rule;
  }
};

// Helper mapper for node explanations
const getNodeInterpretation = (nodeId: string): string => {
  switch (nodeId) {
    case 'root':
      return 'Dies ist der tragende Ast des Modells. Erstes Kriterium ist der mittlere Jahresniederschlag. Er trennt 1.811 feuchtere Böden von 600 trockeneren.';
    case 'cool_europe':
      return 'In kühleren Regionen entscheidet die Landbedeckung. Ackerflächen (Cropland) weisen durch regelmäßigen Pflugbetrieb tendenziell tiefere Humuswerte auf.';
    case 'cool_dry':
      return 'Bei geringen Regenmengen im Norden führt Brachland-Dasein mangels Bedeckung zu starker organischer Mineralisierung und Erosionsneigung.';
    case 'cool_wet':
      return 'Steppengebiete der ariden BSk-Mischklasse neigen lokal zu Versalzung, während maritime Westlagen gesündere Feuchtgefüge besitzen.';
    case 'warm_europe':
      return 'In feuchteren Räumen Südeuropas differenziert weiterer Niederschlag und danach Höhe/Klima. Samples im Knoten: 600 | mittlerer SHI: 3.408.';
    case 'warm_agri':
      return 'Mechanisch gestörte, langanhaltend sonnenbestrahlte Äcker im Süden degradieren schneller als bepflanzte Weideflächen.';
    case 'warm_natural':
      return 'Topografische Gefälle bedingen Erosionseigenschaften; kühlere subalpine Höhenwaldungen bewahren Humus effektiver.';
    case 'leaf_1':
      return 'Dauerhafte Nadel- und Mischwaldforste im Norden mit dicker Nadelhumusauflage (SHI: 3.24).';
    case 'leaf_2':
      return 'Trockene kontinentale Brachflächen ohne Bewuchs mit rasantem Mineralisierungsrisiko (SHI: 2.72).';
    case 'leaf_3':
      return 'Feuchte Weidelandschaften mit stabilem Bewuchs und hoher biologischer Aktivität (SHI: 3.42).';
    case 'leaf_4':
      return 'Klimasensible Ackerflächen mit hohem Feuchtigkeits- und Verdunstungsstress (SHI: 3.03).';
    case 'leaf_5':
      return 'Mediterrane Ackerkulturen mit Neigung zu harten Verkrustungsebenen und Trockenstress (SHI: 3.21).';
    case 'leaf_6':
      return 'Gemischte Waldackerlandschaften im Süden mit lokalem biologischen Schutzgefüge (SHI: 3.55).';
    case 'leaf_7':
      return 'Thermisch hochaktive Flusstäler mit exzellentem ganzjährigen Nährstoffumsatz (SHI: 3.26).';
    case 'leaf_8':
      return 'Hochmontane Krummholzzonen und Bergwälder mit maximal gesicherten Humus-Aggregaten (SHI: 3.65).';
    default:
      return 'Wähle einen beliebigen Zweig aus, um eine automatische bodenökologische Erläuterung der Selektion zu erhalten.';
  }
};

const leafClassNames: Record<string, string> = {
  'leaf_1': 'Ungestörtes Forstland',
  'leaf_2': 'Degradierte Brachflächen',
  'leaf_3': 'Feucht-milde Ackerböden',
  'leaf_4': 'Klimagetrocknete Äcker',
  'leaf_5': 'Klimabegünstigte Höhenweiden',
  'leaf_6': 'Regeneriertes Waldackerland',
  'leaf_7': 'Zonale Feuchtbiotope',
  'leaf_8': 'Stabile Gebirgswaldökosysteme'
};

export default function ModelReport({
  selectedNodeId,
  onSelectNode,
  nodeSamples,
  nodeMeanShi,
  nodeRule
}: ModelReportProps) {
  const isLeaf = selectedNodeId.startsWith('leaf_');
  const displayLabel = isLeaf ? (leafClassNames[selectedNodeId] || selectedNodeId) : getsWortBaumRule(selectedNodeId, nodeRule);

  return (
    <div className="bg-white border border-slate-200 rounded-3xl p-5 shadow-sm space-y-5 select-none">
      
      {/* Header */}
      <div className="border-b border-slate-100 pb-3 flex items-center justify-between">
        <div>
          <h3 className="text-sm font-extrabold text-slate-800 uppercase tracking-wider flex items-center gap-1.5 leading-none">
            <Layers className="w-4 h-4 text-indigo-600" />
            Wissenschaftliches Modellgutachten & Erklärungen
          </h3>
          <p className="text-[10px] text-slate-400 mt-1 leading-normal">
            Ergänzender Modellbezug des Random Forest Schätzers und interaktive Aufschlüsselung aller Zweige nach LUCAS-Methodik.
          </p>
        </div>
      </div>

      {/* Main Grid: Info block left, path list right */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        
        {/* Left Column (5/12): Global Factors & Physics Formula info */}
        <div className="lg:col-span-5 flex flex-col gap-4">
          
          {/* Card 1: Local node details */}
          <div className="bg-slate-50/60 border border-slate-200/50 p-3.5 rounded-2xl flex-1 flex flex-col justify-between">
            <div className="space-y-2">
              <h4 className="font-bold flex items-center gap-1.5 text-[10px] text-indigo-900 uppercase tracking-wider font-sans leading-none">
                <Layers className="w-3.5 h-3.5 text-indigo-600" />
                Random Forest Modell-Bezug
              </h4>
              <p className="text-slate-600 text-[10.5px] leading-relaxed">
                Der gewählte Knoten stellt die lokale Erklärung innerhalb des Entscheidungsbaums her. Im Random Forest veranschaulicht er, unter welchen Umweltbedingungen Faktoren lokal wirksam werden.
              </p>
            </div>

            <div className="bg-white border border-slate-200 p-3 rounded-xl font-mono text-[9.5px] space-y-1.5 shadow-sm mt-3">
              <div className="text-slate-750 font-sans font-extrabold text-[10px] border-b border-indigo-50 pb-1.5 flex items-center justify-between">
                <span>Ausgewählter Knoten / Ast:</span>
                <span className="bg-indigo-600 text-white px-2 py-0.5 rounded font-bold uppercase text-[9px]">
                  {selectedNodeId}
                </span>
              </div>
              <div className="space-y-1.5 text-[10px] leading-relaxed text-slate-600 font-sans">
                <div>
                  <strong>Lokale Weiche:</strong>{" "}
                  <span className="text-indigo-800 font-semibold">{displayLabel}</span>
                </div>
                <div className="flex justify-between items-center bg-slate-50 p-1 px-1.5 rounded text-[9.5px]">
                  <span><strong>Messstellen (N):</strong> {nodeSamples.toLocaleString('de-DE')}</span>
                  <span><strong>Ø SHI:</strong> {nodeMeanShi.toFixed(3)}</span>
                </div>
                <div className="text-[10px] italic border-t border-slate-100 pt-2 mt-1 text-slate-500 font-normal leading-normal">
                  <strong>Erklärung:</strong> {getNodeInterpretation(selectedNodeId)}
                </div>
              </div>
            </div>
          </div>

          {/* Card 2: Equation & Core Physics formula */}
          <div className="bg-slate-50/60 border border-slate-200/50 p-3.5 rounded-2xl flex-1 flex flex-col justify-between">
            <div className="space-y-1">
              <h4 className="font-bold flex items-center gap-1.5 text-[10px] text-pink-900 uppercase tracking-wider font-sans leading-none">
                <BookOpen className="w-3.5 h-3.5 text-pink-600" />
                Formel & Berechnung
              </h4>
              <p className="text-slate-500 text-[10px] leading-relaxed">
                Der Soil Health Index (SHI) modelliert die biologische Bodengüte:
              </p>
            </div>
            
            <div className="bg-white border border-slate-200 p-3 rounded-xl text-center shadow-sm flex flex-col justify-center my-3">
              <div className="text-pink-800 font-bold mb-0.5 text-[9.5px] font-sans">Gleichung: rain ≤ 1010.34</div>
              <div className="text-[10px] font-bold text-slate-800 font-mono py-1.5 border-y border-slate-100 my-1 bg-slate-50/50 rounded">
                SHI = &sum;(w<sub>i</sub>&times;C<sub>i</sub>) &minus; d<sub>stress</sub>
              </div>
              <p className="text-[8px] text-slate-450 leading-tight">
                Kombination aus gewichteter Biomasse, Strukturstabilität und Klimastress.
              </p>
            </div>
          </div>

        </div>

        {/* Middle Column (3/12): Global Top Factors list */}
        <div className="lg:col-span-3 bg-slate-50/60 border border-slate-200/50 p-3.5 rounded-2xl flex flex-col justify-between">
          <div className="space-y-2">
            <h4 className="font-bold flex items-center gap-1.5 text-[10px] text-teal-900 uppercase tracking-wider font-sans leading-none">
              <Award className="w-3.5 h-3.5 text-teal-600" />
              Globale Top-Faktoren
            </h4>
            <p className="text-[10px] text-slate-450 leading-relaxed">
              Globale Feature-Wichtigkeit (Gini-Importance) über den gesamten Random Forest:
            </p>
          </div>

          <ul className="space-y-1.5 text-slate-600 text-[10.5px] mt-3 flex-1 flex flex-col justify-center">
            <li className="flex items-center justify-between gap-1 border-b border-dashed border-slate-150 pb-1">
              <span className="font-medium text-emerald-800">🌧️ Niederschlag (regen)</span>
              <span className="font-mono font-bold bg-emerald-50 text-emerald-700 px-1.5 py-0.2 rounded text-[10px]">30.8%</span>
            </li>
            <li className="flex items-center justify-between gap-1 border-b border-dashed border-slate-150 pb-1">
              <span className="font-medium text-teal-800">🌱 Landbedeckung (cover)</span>
              <span className="font-mono font-bold bg-teal-50 text-teal-700 px-1.5 py-0.2 rounded text-[10px]">19.5%</span>
            </li>
            <li className="flex items-center justify-between gap-1 border-b border-dashed border-slate-150 pb-1">
              <span className="font-medium text-cyan-800">🌡️ Temperatur (temp)</span>
              <span className="font-mono font-bold bg-cyan-50 text-cyan-700 px-1.5 py-0.2 rounded text-[10px]">19.2%</span>
            </li>
            <li className="flex items-center justify-between gap-1 border-b border-dashed border-slate-150 pb-1">
              <span className="font-medium text-indigo-800">⛰️ Geländehöhe (höhe)</span>
              <span className="font-mono font-bold bg-indigo-50 text-indigo-700 px-1.5 py-0.2 rounded text-[10px]">15.9%</span>
            </li>
            <li className="flex items-center justify-between gap-1 border-b border-dashed border-slate-150 pb-1">
              <span className="font-medium text-violet-800">🌍 Klimatyp (klima)</span>
              <span className="font-mono font-bold bg-violet-50 text-violet-700 px-1.5 py-0.2 rounded text-[10px]">9.7%</span>
            </li>
            <li className="flex items-center justify-between gap-1">
              <span className="font-medium text-purple-800">🚜 Landnutzung (nutzung)</span>
              <span className="font-mono font-bold bg-purple-50 text-purple-700 px-1.5 py-0.2 rounded text-[10px]">4.8%</span>
            </li>
          </ul>

          <div className="text-[8.5px] text-slate-400 border-t border-slate-200 mt-3 pt-2 text-center italic">
            Errechnet aus 500 aggregierten Regressionsbäumen.
          </div>
        </div>

        {/* Right Column (4/12): Zweige erklärt list */}
        <div className="lg:col-span-4 bg-slate-50/60 border border-slate-200/50 p-4 rounded-2xl flex flex-col">
          <div className="border-b border-slate-200/60 pb-2 mb-3">
            <h4 className="font-bold flex items-center gap-1.5 text-[10px] text-indigo-900 uppercase tracking-wider font-sans leading-none">
              <BookOpen className="w-3.5 h-3.5 text-indigo-650" />
              Zweige erklärt (Entscheidungspfade)
            </h4>
            <p className="text-[10px] text-slate-500 mt-1 leading-snug">
              Direktes Navigieren der wichtigsten Weichenstellungen des Modells:
            </p>
          </div>

          <div className="space-y-2 flex-1 overflow-y-auto max-h-[290px] pr-1 scrollbar-thin">
            
            {/* Split 1 */}
            <div className="bg-white border border-slate-150 p-2 text-[10px] rounded-xl space-y-1.5 hover:bg-slate-50/20 transition-all">
              <div className="flex justify-between items-center">
                <span className="text-[8px] bg-indigo-50 text-indigo-700 font-bold px-1.5 py-0.1 select-none rounded uppercase">Schnitt 1</span>
                <span className="font-mono text-[8px] text-slate-400 font-bold">Rain ≤ 783 mm</span>
              </div>
              <p className="text-slate-600 text-[9.5px] leading-tight">
                Trennt kühle, feuchtere Regionen West/Zentraleuropas vom trockenen, oft wärmeren mediterranen Süden.
              </p>
              <div className="flex gap-1.5 mt-1">
                <button
                  onClick={() => onSelectNode('cool_europe')}
                  className={`flex-1 text-center py-1 rounded text-[8.5px] font-bold cursor-pointer transition-all ${
                    selectedNodeId === 'cool_europe' ? 'bg-indigo-600 text-white' : 'bg-slate-50 hover:bg-slate-100/85 border border-slate-200'
                  }`}
                >
                  ❄️ Kühl (SHI: 3.32)
                </button>
                <button
                  onClick={() => onSelectNode('warm_europe')}
                  className={`flex-1 text-center py-1 rounded text-[8.5px] font-bold cursor-pointer transition-all ${
                    selectedNodeId === 'warm_europe' ? 'bg-indigo-600 text-white' : 'bg-slate-50 hover:bg-slate-100/85 border border-slate-200'
                  }`}
                >
                  ☀️ Warm (SHI: 3.01)
                </button>
              </div>
            </div>

            {/* Split 2 */}
            <div className="bg-white border border-slate-150 p-2 text-[10px] rounded-xl space-y-1.5 hover:bg-slate-50/20 transition-all">
              <div className="flex justify-between items-center">
                <span className="text-[8px] bg-emerald-50 text-emerald-800 font-bold px-1.5 py-0.1 select-none rounded uppercase">Schnitt 2</span>
                <span className="font-mono text-[8px] text-slate-400 font-bold">Rain ≤ 1010 mm</span>
              </div>
              <p className="text-slate-600 text-[9.5px] leading-tight">
                Südeuropäische Verteilung: Mäßig feuchte Standorte bewahren Aggregatstabilität besser als Dürrezonen.
              </p>
              <div className="flex gap-1.5 mt-1">
                <button
                  onClick={() => onSelectNode('warm_agri')}
                  className={`flex-1 text-center py-1 rounded text-[8.5px] font-bold cursor-pointer transition-all ${
                    selectedNodeId === 'warm_agri' ? 'bg-indigo-600 text-white' : 'bg-slate-50 hover:bg-slate-100/85 border border-slate-200'
                  }`}
                >
                  🚜 Agri (SHI: 2.64)
                </button>
                <button
                  onClick={() => onSelectNode('warm_natural')}
                  className={`flex-1 text-center py-1 rounded text-[8.5px] font-bold cursor-pointer transition-all ${
                    selectedNodeId === 'warm_natural' ? 'bg-indigo-600 text-white' : 'bg-slate-50 hover:bg-slate-100/85 border border-slate-200'
                  }`}
                >
                  🌿 Natur (SHI: 3.48)
                </button>
              </div>
            </div>

            {/* Core alarm leaf node */}
            <div className="bg-rose-50/40 border border-rose-200/50 p-2 text-[10px] rounded-xl space-y-1">
              <div className="flex justify-between items-center">
                <span className="text-[8px] bg-rose-100 text-rose-800 border border-rose-200/50 font-bold px-1.5 py-0.1 select-none rounded uppercase">Trockenzone</span>
                <span className="font-mono text-[8px] text-rose-600 font-bold">Extremer Dürrestress</span>
              </div>
              <p className="text-rose-950 text-[9.5px] leading-tight font-medium">
                Südeuro-Äcker mit &lt; 600 mm Regen leiden unter beschleunigter Winderosion und biologischer Degradierung.
              </p>
              <button
                onClick={() => onSelectNode('leaf_5')}
                className={`w-full py-1 rounded mt-1.5 text-[8.5px] font-bold cursor-pointer flex items-center justify-center gap-1 transition-all ${
                  selectedNodeId === 'leaf_5' ? 'bg-rose-600 text-white' : 'bg-rose-105 border border-rose-200/85 hover:bg-rose-100 text-rose-800'
                }`}
              >
                <ShieldAlert className="w-3 h-3 text-current" />
                ⚠️ Alarmzweig wählen (SHI: 2.38)
              </button>
            </div>

          </div>

          <button
            onClick={() => onSelectNode('root')}
            className="w-full text-center py-1 bg-slate-200 hover:bg-slate-300 transition-colors text-[9px] font-extrabold uppercase rounded-lg border border-slate-300 mt-2 whitespace-nowrap cursor-pointer text-slate-700"
          >
            Alle Filter zurücksetzen
          </button>
        </div>

      </div>

    </div>
  );
}
