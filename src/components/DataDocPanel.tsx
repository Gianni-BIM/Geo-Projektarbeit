import { Database, Table2 } from 'lucide-react';

const sections = [
  {
    id: 'what',
    title: 'Was sind die Daten?',
    body: 'Die Daten bestehen aus räumlichen Stichproben über Europa, die Umweltfaktoren, Landnutzung, Landbedeckung und SHI enthalten.',
  },
  {
    id: 'source',
    title: 'Woher stammen sie?',
    body: 'Die Eingangswerte sind aus Geodatensätzen und Klimamodellen abgeleitet; die Köppen-Geiger-Klassen werden in lesbare Namen übersetzt.',
  },
  {
    id: 'structure',
    title: 'Aufbau',
    body: 'Eine Zeile steht für einen Standort; jede Zeile enthält Koordinaten, Umweltparameter und den SHI-Wert als Zielgröße.',
  },
  {
    id: 'preprocessing',
    title: 'Vorverarbeitung',
    body: 'Koordinaten- und ID-Spalten werden entfernt, seltene Kategorien herausgefiltert und kategoriale Merkmale als Faktoren behandelt.',
  },
] as const;

const attributes = [
  { name: 'SHI', role: 'Zielvariable', type: 'Numerisch' },
  { name: 'rain_mmsqm_mean_1995_2024', role: 'Niederschlag', type: 'Numerisch' },
  { name: 'temp_c_mean_1995_2024', role: 'Temperatur', type: 'Numerisch' },
  { name: 'height_m', role: 'Topographie', type: 'Numerisch' },
  { name: 'land_use', role: 'Landnutzung', type: 'Kategorie' },
  { name: 'land_cover', role: 'Bedeckung', type: 'Kategorie' },
  { name: 'climate_name', role: 'Klimazone', type: 'Kategorie' },
];

export default function DataDocPanel() {
  return (
    <article className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm w-full">
      <div className="mt-4 space-y-2">
        {sections.map((section) => (
          <article key={section.id} className="rounded-2xl border border-slate-200 bg-slate-50/70 p-3">
            <div className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">{section.title}</div>
            <p className="mt-1 text-[10px] leading-relaxed text-slate-600">{section.body}</p>
          </article>
        ))}
      </div>

      <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-3">
        <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.2em] text-slate-700">
          <Table2 className="h-3.5 w-3.5 text-sky-600" />
          Wichtige Attribute
        </div>
        <div className="mt-3 overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <table className="min-w-full text-[10px] text-slate-600">
            <thead className="bg-slate-50 text-[9px] uppercase tracking-[0.2em] text-slate-500">
              <tr>
                <th className="px-2 py-2 text-left">Attribut</th>
                <th className="px-2 py-2 text-left">Bedeutung</th>
                <th className="px-2 py-2 text-left">Typ</th>
              </tr>
            </thead>
            <tbody>
              {attributes.map((item) => (
                <tr key={item.name} className="border-t border-slate-100">
                  <td className="px-2 py-2 font-semibold text-slate-800">{item.name}</td>
                  <td className="px-2 py-2">{item.role}</td>
                  <td className="px-2 py-2">{item.type}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mt-4 flex items-start gap-2 rounded-2xl border border-slate-200 bg-slate-50 p-3 text-[10px] text-slate-600">
        <Database className="mt-0.5 h-3.5 w-3.5 text-sky-600" />
        Die Dokumentation ist direkt auf die R- und CSV-Inputs des Projekts abgestimmt und gibt eine schnelle Orientierung für die Web-App.
      </div>
    </article>
  );
}
