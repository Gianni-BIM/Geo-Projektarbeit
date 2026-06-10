import { Info, Layers, Sparkles } from 'lucide-react';

interface NodeExplanationProps {
  selectedNodeId: string;
  nodeSamples: number;
  nodeMeanShi: number;
  nodeRule: string;
  interpretation: string;
}

function getNodeNarrative(nodeId: string, rule: string, meanShi: number, samples: number) {
  const isLeaf = nodeId.startsWith('leaf_');

  if (nodeId === 'root') {
    return {
      label: 'Root node – erster Split nach Niederschlag',
      summary: 'Der erste Split trennt feuchte von trockeneren Standorten. Niederschlag ist der dominierende Faktor im Random Forest und bestimmt die erste Aufteilung der Daten.',
      detail: `Splitregel: ${rule || 'rain_mmsqm_mean_1995_2024 <= 783.425'}. Im Root-Knoten liegen ${samples.toLocaleString('de-DE')} Beobachtungen mit einem mittleren SHI von ${meanShi.toFixed(3)}.`,
    };
  }

  if (nodeId === 'leaf_8') {
    return {
      label: 'Blattknoten – sehr nasse Höhenlagen',
      summary: 'Dieser Blattknoten beschreibt feuchte, meist höher gelegene Standorte mit stabilen Bodenprozessen. Die Bezeichnung „Höhenlagen (Sehr Nass)“ sollte als feuchte Höhenlagen und nicht als „Höhenlagen sehr nass“ verstanden werden.',
      detail: `Splitregel: ${rule || 'rain_mmsqm_mean_1995_2024 <= 1214.65'}. In diesem Blattknoten liegen ${samples.toLocaleString('de-DE')} Beobachtungen mit einem mittleren SHI von ${meanShi.toFixed(3)} – der höchste Wert im Baum.`,
    };
  }

  return {
    label: isLeaf ? 'Blattknoten' : 'Splitknoten',
    summary: isLeaf
      ? 'Dieser Knoten endet den Pfad im Entscheidungsbaum. Er beschreibt einen klaren Umweltzustand mit einem typischen SHI-Bereich.'
      : 'Dieser Knoten ist ein Splitpunkt im Baum. Er trennt die Daten nach einem Umweltkriterium und leitet den nächsten Pfad ein.',
    detail: `Splitregel: ${rule || 'Kein Splittext verfügbar'}. ${samples.toLocaleString('de-DE')} Beobachtungen, mittlerer SHI ${meanShi.toFixed(3)}.`,
  };
}

export default function NodeExplanation({
  selectedNodeId,
  nodeSamples,
  nodeMeanShi,
  nodeRule,
  interpretation,
}: NodeExplanationProps) {
  const narrative = getNodeNarrative(selectedNodeId, nodeRule, nodeMeanShi, nodeSamples);

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-3 border-b border-slate-100 pb-3">
        <div>
          <p className="text-[10px] font-black uppercase tracking-[0.25em] text-indigo-600">Zweig-Erklärung</p>
          <h3 className="mt-1 text-sm font-extrabold text-slate-800">Ausgewählter Knoten im Fokus</h3>
          <p className="mt-1 text-[10px] text-slate-400">Die Erklärung folgt der aktuellen Auswahl im Entscheidungsbaum. Im Random Forest heißt das im Kern Splitpunkt bzw. Blattknoten – nicht „Weiche“.</p>
        </div>
        <div className="rounded-2xl border border-indigo-100 bg-indigo-50 px-3 py-2 text-[10px] text-indigo-800 shadow-sm">
          Knoten: {selectedNodeId}
        </div>
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <article className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
          <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.2em] text-slate-700">
            <Layers className="h-3.5 w-3.5 text-indigo-600" />
            Split / Blattknoten
          </div>
          <p className="mt-3 text-sm font-semibold text-slate-800">{narrative.label}</p>
          <p className="mt-2 text-[11px] text-slate-600">{narrative.summary}</p>
          <div className="mt-3 rounded-xl border border-slate-200 bg-white p-3 text-[11px] text-slate-600">
            <strong className="text-slate-800">Interpretation:</strong> {interpretation || narrative.detail}
          </div>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
          <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.2em] text-emerald-700">
            <Sparkles className="h-3.5 w-3.5 text-emerald-600" />
            Kurzfazit
          </div>
          <ul className="mt-3 space-y-2 text-[11px] text-slate-600">
            <li className="rounded-xl border border-slate-100 bg-slate-50 p-2">Ø SHI im Knoten: <strong>{nodeMeanShi.toFixed(3)}</strong></li>
            <li className="rounded-xl border border-slate-100 bg-slate-50 p-2">Beobachtete Messstellen: <strong>{nodeSamples.toLocaleString('de-DE')}</strong></li>
            <li className="rounded-xl border border-slate-100 bg-slate-50 p-2">{narrative.detail}</li>
          </ul>
          <div className="mt-3 flex items-start gap-2 rounded-xl border border-amber-100 bg-amber-50 p-3 text-[10px] text-amber-900">
            <Info className="mt-0.5 h-3.5 w-3.5 shrink-0" />
            Die Erklärung basiert auf dem aktuellen Split bzw. Blattknoten und nicht auf einer generischen „Weiche“.
          </div>
        </article>
      </div>
    </section>
  );
}
