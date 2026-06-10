import { useState } from 'react';
import { TreeNode } from '../types';
import { getDecisionPath } from '../data/decisionTreeModel';

interface DecisionTreeProps {
  tree: TreeNode;
  selectedNodeId: string;
  onSelectNode: (nodeId: string) => void;
}

export default function DecisionTree({
  tree,
  selectedNodeId,
  onSelectNode,
}: DecisionTreeProps) {
  const [viewMode, setViewMode] = useState<'technical' | 'descriptive'>('technical');

  // Position map scaled down to prevent overlaps and guarantee visibility within the SVG viewBox
  const positions: Record<string, { x: number; y: number; width: number; height: number }> = {
    'root': { x: 500, y: 15, width: 155, height: 72 },
    'cool_europe': { x: 250, y: 110, width: 155, height: 72 },
    'warm_europe': { x: 750, y: 110, width: 155, height: 72 },
    'cool_dry': { x: 125, y: 205, width: 145, height: 72 },
    'cool_wet': { x: 375, y: 205, width: 145, height: 72 },
    'warm_agri': { x: 625, y: 205, width: 145, height: 72 },
    'warm_natural': { x: 875, y: 205, width: 145, height: 72 },
    'leaf_1': { x: 62, y: 300, width: 95, height: 76 },
    'leaf_2': { x: 187, y: 300, width: 95, height: 76 },
    'leaf_3': { x: 312, y: 300, width: 95, height: 76 },
    'leaf_4': { x: 437, y: 300, width: 95, height: 76 },
    'leaf_5': { x: 562, y: 300, width: 95, height: 76 },
    'leaf_6': { x: 687, y: 300, width: 95, height: 76 },
    'leaf_7': { x: 812, y: 300, width: 95, height: 76 },
    'leaf_8': { x: 937, y: 300, width: 95, height: 76 },
  };

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

  // Human-friendly names for leaf classifications
  const leafClassNames: Record<string, string> = {
    'leaf_1': 'Ungestörtes Forstland',
    'leaf_2': 'Degradierte Brachflächen',
    'leaf_3': 'Feucht-milde Weideländer',
    'leaf_4': 'Klimagetrocknete Äcker',
    'leaf_5': 'Klimabegünstigte Höhenweiden',
    'leaf_6': 'Regeneriertes Waldackerland',
    'leaf_7': 'Zonale Feuchtbiotope',
    'leaf_8': 'Stabile Gebirgswaldökosysteme'
  };

  const activePath = getDecisionPath(tree, selectedNodeId) || [];
  const activeNodeIds = new Set(activePath.map(n => n.id));

  // Render a single node block (SVG Mode)
  function renderNode(node: TreeNode) {
    const pos = positions[node.id];
    if (!pos) return null;

    const isSelected = selectedNodeId === node.id;
    const isActiveInPath = activeNodeIds.has(node.id);

    // Color code leaf nodes by their mean SHI value
    let fillClass = 'bg-white border-slate-200 text-slate-800 hover:border-slate-400';
    let headerStyle = 'bg-slate-100 border-slate-200 text-slate-700';

    if (node.isLeaf) {
      const val = node.meanShi;
      if (val < 2.5) {
        fillClass = 'bg-rose-50 border-rose-200 text-rose-950 font-medium hover:border-rose-450 hover:bg-rose-100/70 shadow-xs';
        headerStyle = 'bg-rose-100/90 border-rose-200 text-rose-800 font-bold';
      } else if (val < 3.0) {
        fillClass = 'bg-amber-50/50 border-amber-200 text-amber-950 hover:border-amber-405 hover:bg-amber-100/70 shadow-xs';
        headerStyle = 'bg-amber-100 border-amber-200 text-amber-800 font-bold';
      } else if (val < 3.5) {
        fillClass = 'bg-emerald-50/40 border-emerald-200 text-emerald-950 hover:border-emerald-405 hover:bg-emerald-100/70 shadow-xs';
        headerStyle = 'bg-emerald-100 border-emerald-200 text-emerald-800 font-bold';
      } else {
        fillClass = 'bg-emerald-50 border-emerald-300 text-emerald-950 font-bold hover:border-emerald-505 hover:bg-emerald-100 shadow-xs';
        headerStyle = 'bg-emerald-600 border-emerald-600 text-white font-bold';
      }
    }

    if (isSelected) {
      fillClass = `${fillClass} ring-4 ring-indigo-500 ring-offset-1 border-indigo-500`;
    } else if (isActiveInPath) {
      fillClass = `${fillClass} border-indigo-400 ring-2 ring-indigo-150`;
    }

    // Node content based on view mode (Technical Formulas vs Descriptive Classes)
    let nodeLabel = '';
    if (node.isLeaf) {
      nodeLabel = leafClassNames[node.id] || node.name;
    } else {
      if (viewMode === 'descriptive') {
        nodeLabel = getsWortBaumRule(node.id, node.rule);
      } else {
        nodeLabel = node.rule;
      }
    }

    return (
      <foreignObject
        key={node.id}
        x={pos.x - pos.width / 2}
        y={pos.y}
        width={pos.width}
        height={pos.height}
        className="overflow-visible"
      >
        <button
          onClick={() => onSelectNode(node.id)}
          className={`flex flex-col text-left rounded-xl border w-full h-full cursor-pointer select-none transition-all duration-300 shadow-xs ${fillClass}`}
          id={`tree-node-${node.id}`}
        >
          {/* Node Split / Name Indicator */}
          <div className={`px-1.5 py-0.5 select-none rounded-t-xl text-[8px] font-bold truncate w-full border-b ${headerStyle}`} title={nodeLabel}>
            {node.isLeaf ? 'BLATTKNOTEN' : 'SPLIT'}
          </div>

          <div className="p-1 px-2 flex-1 flex flex-col justify-between leading-snug text-[8px] select-none">
            {/* Rule or Category Name */}
            <span className="font-extrabold text-slate-800 tracking-tight block truncate text-[9px]" title={nodeLabel}>
              {nodeLabel}
            </span>

            {viewMode === 'descriptive' ? (
              <div className="flex flex-col gap-0.5 border-t border-slate-100/60 pt-0.5 text-[7.5px] text-slate-500 leading-none">
                <div className="flex justify-between">
                  <span>Varianz:</span>
                  <span className="font-semibold text-slate-700">
                    {node.squared_error && node.squared_error >= 0.15 ? 'Mäßig' : (node.squared_error && node.squared_error >= 0.08 ? 'Gering' : 'E.Gering')}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span>Proben:</span>
                  <span className="font-semibold text-slate-700">{node.sampleCount.toLocaleString('de-DE')}</span>
                </div>
                <div className="flex justify-between font-bold text-emerald-800 border-t border-emerald-50/50 mt-0.5 pt-0.5">
                  <span>Ø SHI:</span>
                  <span className="font-mono">{node.meanShi.toFixed(3)}</span>
                </div>
              </div>
            ) : (
              <div className="flex flex-col gap-0.5 border-t border-slate-100/60 pt-0.5 text-[7.5px] font-mono text-slate-400 leading-none">
                <div className="flex justify-between">
                  <span>sq_err:</span>
                  <span className="text-slate-600">{(node.squared_error ?? 0.1).toFixed(3)}</span>
                </div>
                <div className="flex justify-between">
                  <span>samples:</span>
                  <span className="text-slate-600">{node.sampleCount.toLocaleString()}</span>
                </div>
                <div className="flex justify-between font-bold text-sky-800 border-t border-sky-50 pt-0.5">
                  <span>value:</span>
                  <span>{node.meanShi.toFixed(3)}</span>
                </div>
              </div>
            )}
          </div>
        </button>
      </foreignObject>
    );
  }

  // Draw smooth cubic Bezier link curves between parents and child splits
  function renderLinks(node: TreeNode) {
    if (!node.children) return [];

    const parentPos = positions[node.id];
    const leftChildPos = positions[node.children[0].id];
    const rightChildPos = positions[node.children[1].id];

    if (!parentPos || !leftChildPos || !rightChildPos) return [];

    const startX = parentPos.x;
    const startY = parentPos.y + parentPos.height;

    const leftEndX = leftChildPos.x;
    const leftEndY = leftChildPos.y;

    const rightEndX = rightChildPos.x;
    const rightEndY = rightChildPos.y;

    const midY = (startY + leftEndY) / 2;

    const leftActive = activeNodeIds.has(node.id) && activeNodeIds.has(node.children[0].id);
    const rightActive = activeNodeIds.has(node.id) && activeNodeIds.has(node.children[1].id);

    const leftPathD = `M ${startX} ${startY} C ${startX} ${midY}, ${leftEndX} ${midY}, ${leftEndX} ${leftEndY}`;
    const rightPathD = `M ${startX} ${startY} C ${startX} ${midY}, ${rightEndX} ${midY}, ${rightEndX} ${rightEndY}`;

    return [
      // Left branch curve
      <g key={`${node.id}-left-branch`}>
        <path
          d={leftPathD}
          fill="none"
          stroke={leftActive ? '#4f46e5' : '#cbd5e1'}
          strokeWidth={leftActive ? 2.5 : 1.0}
          className="transition-all duration-300"
        />
        <rect
          x={((startX + leftEndX) / 2) - 13}
          y={midY - 6}
          width="26"
          height="12"
          rx="3"
          fill="#f8fafc"
          stroke={leftActive ? '#818cf8' : '#e2e8f0'}
          strokeWidth="1"
        />
        <text
          x={(startX + leftEndX) / 2}
          y={midY + 2.5}
          textAnchor="middle"
          className={`font-black font-mono text-[7px] select-none ${leftActive ? 'fill-indigo-700' : 'fill-slate-500'}`}
        >
          JA
        </text>
      </g>,

      // Right branch curve
      <g key={`${node.id}-right-branch`}>
        <path
          d={rightPathD}
          fill="none"
          stroke={rightActive ? '#4f46e5' : '#cbd5e1'}
          strokeWidth={rightActive ? 2.5 : 1.0}
          className="transition-all duration-300"
        />
        <rect
          x={((startX + rightEndX) / 2) - 13}
          y={midY - 6}
          width="26"
          height="12"
          rx="3"
          fill="#f8fafc"
          stroke={rightActive ? '#818cf8' : '#e2e8f0'}
          strokeWidth="1"
        />
        <text
          x={(startX + rightEndX) / 2}
          y={midY + 2.5}
          textAnchor="middle"
          className={`font-black font-mono text-[7px] select-none ${rightActive ? 'fill-indigo-700' : 'fill-slate-500'}`}
        >
          NEIN
        </text>
      </g>,

      ...renderLinks(node.children[0]),
      ...renderLinks(node.children[1]),
    ];
  }

  // Gather list of foreign objects recursively
  function collectNodes(node: TreeNode): TreeNode[] {
    const list = [node];
    if (node.children) {
      list.push(...collectNodes(node.children[0]));
      list.push(...collectNodes(node.children[1]));
    }
    return list;
  }

  const allNodeObjects = collectNodes(tree);

  return (
    <div className="flex flex-col bg-white border border-slate-200 rounded-3xl p-4 shadow-xs w-full h-full min-h-[440px]">
      
      {/* Header Block & Mode switcher */}
      <div className="flex justify-between items-center mb-3 border-b border-slate-100 pb-2.5 select-none">
        <div>
          <h3 className="text-xs font-black text-slate-800 uppercase tracking-wider leading-none">
            Entscheidungsbaum
          </h3>
        </div>
        {/* Simplified display mode selector tabs */}
        <div className="flex bg-slate-100/90 p-0.5 rounded-xl border border-slate-200/50">
          <button
            onClick={() => setViewMode('technical')}
            className={`cursor-pointer px-3 py-1 rounded-lg text-[9px] font-extrabold tracking-wide transition-all ${
              viewMode === 'technical' ? 'bg-white text-slate-900 shadow-xs border border-slate-200/30 font-semibold' : 'text-slate-500'
            }`}
          >
            Anzeige 1
          </button>
          <button
            onClick={() => setViewMode('descriptive')}
            className={`cursor-pointer px-3 py-1 rounded-lg text-[9px] font-extrabold tracking-wide transition-all ${
              viewMode === 'descriptive' ? 'bg-white text-slate-900 shadow-xs border border-slate-200/30' : 'text-slate-500'
            }`}
          >
            Anzeige 2
          </button>
        </div>
      </div>

      {/* RENDER MODEL SVG */}
      <div className="flex flex-col flex-1">
        <div className="relative flex-1 w-full overflow-x-auto overflow-y-hidden select-none bg-slate-50/20 rounded-2xl p-1 border border-slate-100/50">
          <div className="min-w-[940px] w-full flex items-center justify-center">
            <svg
              viewBox="0 0 1000 400"
              width="100%"
              height="390px"
              className="overflow-visible"
            >
              {renderLinks(tree)}
              {allNodeObjects.map(renderNode)}
            </svg>
          </div>
        </div>

        {/* Subtle footer control help */}
        <div className="flex justify-between items-center text-[10px] text-slate-450 mt-2.5 border-t border-slate-100 pt-2 pb-0.5 select-none">
          <span> <i>Klicke auf ein beliebigen Knoten, um tiefergehende Statistiken anzuzeigen.</i></span>
          <button 
            onClick={() => onSelectNode('root')}
            className="inline-flex items-center gap-1 bg-white hover:bg-gray-50 border border-gray-200 text-gray-700 px-2 py-0.5 rounded text-[9.5px] font-medium cursor-pointer transition-colors"          >
            Filter aufheben
          </button>
        </div>
      </div>
      
    </div>
  );
}
