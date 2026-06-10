import { useState } from 'react';
import { SoilPoint } from '../types';
import { AlertCircle } from 'lucide-react';

interface ScientificChartsProps {
  filteredPoints: SoilPoint[];
}

export default function ScientificCharts({ filteredPoints }: ScientificChartsProps) {
  const [activeTab, setActiveTab] = useState<'importance' | 'obs_vs_pred' | 'residuals' | 'correlation' | 'parameters'>('importance');

  // Calculates Pearson correlation coefficient between two numeric arrays
  function calculatePearson(x: number[], y: number[]): number {
    const n = x.length;
    if (n === 0) return 0;
    const sumX = x.reduce((a, b) => a + b, 0);
    const sumY = y.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((s, val, i) => s + val * y[i], 0);
    const sumX2 = x.reduce((s, val) => s + val * val, 0);
    const sumY2 = y.reduce((s, val) => s + val * val, 0);

    const num = n * sumXY - sumX * sumY;
    const den = Math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    if (den === 0) return 0;
    return num / den;
  }

  const featureImportances = [
    { name: 'Niederschlag (Rain)', value: 34.0, color: 'bg-emerald-600', code: 'rain_mmsqm_mean_1995_2024' },
    { name: 'Landbedeckung (Land Cover)', value: 30.9, color: 'bg-teal-600', code: 'land_cover' },
    { name: 'Temperatur (Temp)', value: 12.6, color: 'bg-cyan-600', code: 'temp_c_mean_1995_2024' },
    { name: 'Klimazone (Climate Name)', value: 8.1, color: 'bg-violet-600', code: 'climate_name' },
    { name: 'Geländehöhe (Elevation)', value: 8.0, color: 'bg-indigo-600', code: 'height_m' },
    { name: 'Landnutzung (Land Use)', value: 6.4, color: 'bg-purple-600', code: 'land_use' }
  ];

  // Correlation Matrix Variables
  const correlationVariables = [
    { label: 'Soil Health (SHI)', key: 'SHI' },
    { label: 'Niederschlag (Rain)', key: 'rain_mmsqm_mean_1995_2024' },
    { label: 'Temperatur (Temp)', key: 'temp_c_mean_1995_2024' },
    { label: 'Höhe (Elevation)', key: 'height_m' }
  ];

  // Calculate Pearson correlation matrix for currently filtered points
  const correlationMatrix = correlationVariables.map((v1) => {
    return correlationVariables.map((v2) => {
      const x = filteredPoints.map(p => Number(p[v1.key as keyof SoilPoint] || 0));
      const y = filteredPoints.map(p => Number(p[v2.key as keyof SoilPoint] || 0));
      return calculatePearson(x, y);
    });
  });

  const paramLogs = [
    { run: 1, mtry: 2, mincriterion: 0.9, n_estimators: 500, r2: 0.367, rmse: 0.356, status: 'Standard' },
    { run: 2, mtry: 3, mincriterion: 0.95, n_estimators: 500, r2: 0.367, rmse: 0.356, status: 'Robust' },
    { run: 3, mtry: 3, mincriterion: 0.9, n_estimators: 500, r2: 0.373, rmse: 0.355, status: 'Selektiertes Optimum' },
    { run: 4, mtry: 4, mincriterion: 0.9, n_estimators: 500, r2: 0.372, rmse: 0.355, status: 'Gleichwertig' },
    { run: 5, mtry: 2, mincriterion: 0.99, n_estimators: 500, r2: 0.352, rmse: 0.360, status: 'Streng (High Signif)' },
  ];

  // Prepare variables for charts
  const pointsWithPreds = filteredPoints.filter(p => p.pred_shi !== undefined);

  // SVG dimensions
  const viewWidth = 500;
  const viewHeight = 280;
  const padding = 45;

  return (
    <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm h-full flex flex-col">
      {/* Sci Tabs Header */}
      <div className="flex justify-between items-center border-b border-slate-100 pb-2.5 flex-wrap gap-2 select-none">
        {/* Dynamic Scientific tabs switcher */}
        <div className="flex bg-slate-100 p-0.5 rounded-lg border border-slate-200/50 flex-wrap gap-1">
          <button
            onClick={() => setActiveTab('importance')}
            className={`cursor-pointer px-2.5 py-1 rounded-md text-[10px] font-bold transition-all ${
              activeTab === 'importance' ? 'bg-white hover:bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-850'
            }`}
          >
           Permutations-Importance
          </button>
          <button
            id="tab-obs-vs-pred"
            onClick={() => setActiveTab('obs_vs_pred')}
            className={`cursor-pointer px-2.5 py-1 rounded-md text-[10px] font-bold transition-all ${
              activeTab === 'obs_vs_pred' ? 'bg-white hover:bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-850'
            }`}
          >
           Obs. vs Pred.
          </button>
          <button
            onClick={() => setActiveTab('residuals')}
            className={`cursor-pointer px-2.5 py-1 rounded-md text-[10px] font-bold transition-all ${
              activeTab === 'residuals' ? 'bg-white hover:bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-850'
            }`}
          >
           Residuen
          </button>
          <button
            id="tab-correlation"
            onClick={() => setActiveTab('correlation')}
            className={`cursor-pointer px-2.5 py-1 rounded-md text-[10px] font-bold transition-all ${
              activeTab === 'correlation' ? 'bg-white hover:bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-850'
            }`}
          >
           Korrelation
          </button>
          <button
            onClick={() => setActiveTab('parameters')}
            className={`cursor-pointer px-2.5 py-1 rounded-md text-[10px] font-bold transition-all ${
              activeTab === 'parameters' ? 'bg-white hover:bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-850'
            }`}
          >
           Tuning
          </button>
        </div>
      </div>

      {/* TABS CONTAINER */}
      <div className="flex-1 mt-4 flex flex-col justify-center">

        {/* Tab 1: Feature Importance (Mean Decrease Gini) */}
        {activeTab === 'importance' && (
          <div className="space-y-4 animate-fade-in">
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-[11px] text-slate-650 leading-relaxed font-sans mb-1">
              <strong className="text-slate-850 font-semibold block mb-0.5"> Permutations-Importance (Conditional Inference):</strong>
              Die Wichtigkeit basiert auf der Veränderung der Modellgüte bei zufälliger Permutation eines Merkmals und spiegelt damit die echte Bedeutung im Random-Forest-Setup wider.
              <strong className="text-emerald-700"> Niederschlag</strong> bleibt der stärkste Einflussfaktor im R-Skript-Workflow.
            </div>

            <div className="space-y-3.5 pr-1">
              {featureImportances.map((f) => (
                <div key={f.name} className="flex flex-col space-y-1" title={`${f.name}: ${f.value.toFixed(1)}% Permutations-Importance`}>
                  <div className="flex justify-between items-center text-[10.5px]">
                    <span className="font-semibold text-slate-700 font-sans">{f.name}</span>
                    <span className="font-mono text-emerald-700 font-bold">{f.value.toFixed(1)}%</span>
                  </div>
                  <div className="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden flex">
                    <div 
                      className={`h-full ${f.color} rounded-full transition-all duration-700`}
                      style={{ width: `${f.value * 2}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Tab 2: Observed vs Predicted Scatterplot */}
        {activeTab === 'obs_vs_pred' && (
          <div className="space-y-4 animate-fade-in flex flex-col">
            <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 text-[10.5px] text-slate-650 leading-relaxed font-sans">
              <strong className="text-slate-850 font-semibold block mb-0.5"> Observed vs. Predicted (Beobachtet vs. Berechnet):</strong>
              Zeigt die Anpassungsgüte des Modells. Perfekt vorhergesagte Punkte lägen exakt auf der gestrichelten 1:1 Identity-Linie.
              Unsere OOB-Güte liegt stabil bei <strong className="text-indigo-700">R² = 0.373</strong>.
            </div>

            {pointsWithPreds.length > 0 ? (
              <div className="flex justify-center items-center">
                <svg width="100%" height={viewHeight} viewBox={`0 0 ${viewWidth} ${viewHeight}`} className="overflow-visible max-w-[480px]">
                  {/* Grid Lines */}
                  {[2.0, 2.5, 3.0, 3.5, 4.0].map((coord) => {
                    // x scale: 1.5 to 4.3 -> maps to padding to width-padding
                    // y scale: 1.5 to 4.3 -> maps to height-padding to padding
                    const x = padding + ((coord - 1.5) / (4.3 - 1.5)) * (viewWidth - 2 * padding);
                    const y = viewHeight - padding - ((coord - 1.5) / (4.3 - 1.5)) * (viewHeight - 2 * padding);
                    return (
                      <g key={coord}>
                        <line x1={x} y1={padding} x2={x} y2={viewHeight - padding} stroke="#f1f5f9" strokeWidth="1" />
                        <line x1={padding} y1={y} x2={viewWidth - padding} y2={y} stroke="#f1f5f9" strokeWidth="1" />
                        <text x={x} y={viewHeight - padding + 12} textAnchor="middle" className="fill-slate-400 text-[8px] font-mono">{coord.toFixed(1)}</text>
                        <text x={padding - 8} y={y + 3} textAnchor="end" className="fill-slate-400 text-[8px] font-mono">{coord.toFixed(1)}</text>
                      </g>
                    );
                  })}

                  {/* 1:1 Identity Line */}
                  <line 
                    x1={padding} 
                    y1={viewHeight - padding} 
                    x2={viewWidth - padding} 
                    y2={padding} 
                    stroke="#94a3b8" 
                    strokeWidth="1.5" 
                    strokeDasharray="4 4" 
                  />

                  {/* Scatter Points */}
                  {pointsWithPreds.map((p, idx) => {
                    const x = padding + ((p.SHI - 1.5) / (4.3 - 1.5)) * (viewWidth - 2 * padding);
                    const y = viewHeight - padding - (((p.pred_shi || 3.1) - 1.5) / (4.3 - 1.5)) * (viewHeight - 2 * padding);
                    return (
                      <circle 
                        key={idx} 
                        cx={x} 
                        cy={y} 
                        r="3.5" 
                        className="fill-indigo-500/60 stroke-white stroke-[0.5]" 
                      />
                    );
                  })}

                  {/* Axis Legend labels */}
                  <text x={viewWidth / 2} y={viewHeight - 12} textAnchor="middle" className="fill-slate-700 text-[10px] font-bold font-sans">Beobachteter SHI (Observed)</text>
                  <text x="12" y={viewHeight / 2} textAnchor="middle" transform={`rotate(-90 12 ${viewHeight / 2})`} className="fill-slate-700 text-[10px] font-bold font-sans">Prognostizierter SHI (Predicted)</text>
                </svg>
              </div>
            ) : (
              <div className="py-12 text-center text-xs text-slate-400">Keine Punkte zur Diagrammdarstellung vorhanden</div>
            )}
          </div>
        )}

        {/* Tab 3: Residual Analysis Plot */}
        {activeTab === 'residuals' && (
          <div className="space-y-4 animate-fade-in flex flex-col">
            <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 text-[10.5px] text-slate-650 leading-relaxed font-sans">
              <strong className="text-slate-850 font-semibold block mb-0.5"> Residualanalyse (Residuen vs. Vorhersage):</strong>
              Das Diagramm trägt den Vorhersagewert (x) gegen den Fehler/Residuum `(Beobachtet - Vorhergesagt)` auf. 
              Eine ausgeglichene, gleichmäßige Streuung um die rote Nulllinie herum signalisiert Homoskedastizität (gesicherte Fehlerverteilung).
            </div>

            {pointsWithPreds.length > 0 ? (
              <div className="flex justify-center items-center">
                <svg width="100%" height={viewHeight} viewBox={`0 0 ${viewWidth} ${viewHeight}`} className="overflow-visible max-w-[480px]">
                  {/* Grid Lines & Axis */}
                  {[-1.0, -0.5, 0.0, 0.5, 1.0].map((residual) => {
                    const y = viewHeight / 2 - (residual / 1.2) * (viewHeight / 2 - padding);
                    return (
                      <g key={residual}>
                        <line x1={padding} y1={y} x2={viewWidth - padding} y2={y} stroke={residual === 0 ? '#ef4444' : '#f1f5f9'} strokeWidth={residual === 0 ? 1.5 : 1} />
                        <text x={padding - 8} y={y + 3} textAnchor="end" className="fill-slate-400 text-[8px] font-mono">{residual.toFixed(1)}</text>
                      </g>
                    );
                  })}
                  {[2.0, 2.5, 3.0, 3.5, 4.0].map((pred) => {
                    const x = padding + ((pred - 1.5) / (4.3 - 1.5)) * (viewWidth - 2 * padding);
                    return (
                      <g key={pred}>
                        <line x1={x} y1={padding} x2={x} y2={viewHeight - padding} stroke="#f1f5f9" strokeWidth="1" />
                        <text x={x} y={viewHeight - padding + 12} textAnchor="middle" className="fill-slate-400 text-[8px] font-mono">{pred.toFixed(1)}</text>
                      </g>
                    );
                  })}

                  {/* Draw Scatter Points (Residuals) */}
                  {pointsWithPreds.map((p, idx) => {
                    const pred = p.pred_shi || 3.12;
                    const residual = p.SHI - pred;

                    const x = padding + ((pred - 1.5) / (4.3 - 1.5)) * (viewWidth - 2 * padding);
                    const y = viewHeight / 2 - (residual / 1.2) * (viewHeight / 2 - padding);
                    return (
                      <circle 
                        key={idx} 
                        cx={x} 
                        cy={y} 
                        r="3.5" 
                        className="fill-teal-500/60 stroke-white stroke-[0.5]" 
                      />
                    );
                  })}

                  {/* Axis labels */}
                  <text x={viewWidth / 2} y={viewHeight - 12} textAnchor="middle" className="fill-slate-700 text-[10px] font-bold font-sans">Vorhergesagter Wert (Predicted SHI)</text>
                  <text x="12" y={viewHeight / 2} textAnchor="middle" transform={`rotate(-90 12 ${viewHeight / 2})`} className="fill-slate-700 text-[10px] font-bold font-sans">Residuen (Obs - Pred)</text>
                </svg>
              </div>
            ) : (
              <div className="py-12 text-center text-xs text-slate-400">Keine Punkte zur Diagrammdarstellung vorhanden</div>
            )}
          </div>
        )}

        {/* Tab 4: Interactive Pearson Correlation Matrix */}
        {activeTab === 'correlation' && (
          <div className="space-y-4 animate-fade-in">
            <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 text-[10.5px] text-slate-650 leading-relaxed font-sans">
              <strong className="text-slate-850 font-semibold block mb-0.5"> Pearson Korrelationsmatrix (Dynamische Berechnung):</strong>
              Berechnet in Echtzeit den linearen Zusammenhang zwischen den Einflussfaktoren im aktuellen Filterset. 
              Mögliche Ausprägungen reichen von <span className="text-red-700 font-bold">-1.0 (anti-proportional)</span> über <span className="text-slate-500 font-bold">0.0 (unabhängig)</span> bis <span className="text-teal-700 font-bold">+1.0 (völlig proportional)</span>.
            </div>

            {/* Heat table matrix UI */}
            <div className="overflow-x-auto">
              <table className="min-w-full text-center border-collapse text-[10.5px]">
                <thead>
                  <tr className="border-b border-slate-200">
                    <th className="p-1 px-2 text-left text-slate-500">Parameter</th>
                    {correlationVariables.map((v) => (
                      <th key={v.label} className="p-1 px-2 font-semibold text-slate-700 w-24 leading-tight truncate" title={v.label}>
                        {v.label.split(' ')[0]}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {correlationVariables.map((v1, idx1) => (
                    <tr key={v1.label} className="border-b border-slate-100 hover:bg-slate-50/50">
                      <td className="p-2 text-left font-semibold text-slate-800 shrink-0 truncate">{v1.label}</td>
                      {correlationVariables.map((v2, idx2) => {
                        const score = correlationMatrix[idx1][idx2];
                        let heatBg = 'bg-slate-100 text-slate-800';
                        if (score > 0.6) heatBg = 'bg-teal-100 text-teal-900 border border-teal-200/40 font-bold';
                        else if (score > 0.2) heatBg = 'bg-teal-50 text-teal-800 border border-teal-100/30';
                        else if (score < -0.4) heatBg = 'bg-rose-100 text-rose-900 border border-rose-200/40 font-bold';
                        else if (score < -0.1) heatBg = 'bg-rose-50/80 text-rose-800 border border-rose-100/30';

                        return (
                          <td
                            key={v2.label}
                            className={`p-2 font-mono ${heatBg}`}
                            title={`Pearson-Korrelation zwischen ${v1.label} und ${v2.label}: ${score.toFixed(2)}`}
                          >
                            {score.toFixed(2)}
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            
            <div className="flex items-center gap-1.5 text-[9.5px] text-slate-400/90 leading-tight">
              <AlertCircle className="w-3.5 h-3.5 text-indigo-500 shrink-0" />
              <span>Die berechneten Pearson-Sätze weichen je nach aktiver Filtereinschränkung ab, was wertvolle ökologische Nischen offenbart!</span>
            </div>
          </div>
        )}

        {/* Tab 5: Hyperparameters Tuning Log */}
        {activeTab === 'parameters' && (
          <div className="space-y-4 animate-fade-in font-sans">
            <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-100 text-[10.5px] text-slate-650 leading-relaxed">
              <strong className="text-slate-850 font-semibold block mb-0.5"> Hyperparameter-Optimierungs-Historie:</strong>
              Zeigt den modellbezogenen Trainingsverlauf an. Der finale Forest mit 500 Bäumen und einem mincriterion von 0.9 erreicht das R²-Optimum von <strong className="text-emerald-700">0.373</strong>.
            </div>

            <div className="overflow-x-auto rounded-xl border border-slate-150">
              <table className="min-w-full divide-y divide-slate-150 text-[10px]">
                <thead className="bg-[#f8fafc] text-[9.5px]">
                  <tr>
                    <th className="p-2 py-2.5 text-left text-slate-500 font-bold uppercase tracking-wider">Run</th>
                    <th className="p-2 py-2.5 text-slate-500 font-bold uppercase tracking-wider">Bäume (Est.)</th>
                    <th className="p-2 py-2.5 text-slate-500 font-bold uppercase tracking-wider">mtry</th>
                    <th className="p-2 py-2.5 text-slate-500 font-bold uppercase tracking-wider">mincriterion</th>
                    <th className="p-2 py-2.5 text-slate-500 font-bold uppercase tracking-wider text-emerald-800">R² Score</th>
                    <th className="p-2 py-2.5 text-slate-500 font-bold uppercase tracking-wider text-rose-800">RMSE</th>
                    <th className="p-2 py-2.5 text-left text-slate-500 font-bold uppercase tracking-wider">Status</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-slate-100 font-mono text-center">
                  {paramLogs.map((p) => {
                    const isBest = p.run === 3;
                    return (
                      <tr key={p.run} className={`hover:bg-slate-50/50 ${isBest ? 'bg-indigo-50/40 font-bold text-indigo-950' : 'text-slate-600'}`}>
                        <td className="p-2 text-left font-bold">{p.run}</td>
                        <td className="p-2">{p.n_estimators}</td>
                        <td className="p-2">{p.mtry}</td>
                        <td className="p-2">{p.mincriterion}</td>
                        <td className="p-2 text-emerald-700 font-bold">{p.r2.toFixed(3)}</td>
                        <td className="p-2 text-rose-700">{p.rmse.toFixed(3)}</td>
                        <td className="p-2 text-left text-[9px] font-sans">
                          <span className={`px-2 py-0.5 rounded-full font-bold ${
                            isBest ? 'bg-emerald-100 text-emerald-800 border border-emerald-200' : 'bg-slate-100 text-slate-500'
                          }`}>
                            {p.status}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
