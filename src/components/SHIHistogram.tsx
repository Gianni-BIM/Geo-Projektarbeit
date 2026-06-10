import { useState, useMemo } from 'react';

interface SHIHistogramProps {
  shiValues: number[];
}

export default function SHIHistogram({ shiValues }: SHIHistogramProps) {
  const [hoveredBin, setHoveredBin] = useState<number | null>(null);

  // Define 18 narrow bins from 1.5 to 4.2
  const minRange = 1.5;
  const maxRange = 4.2;
  const binCount = 18;
  const binWidth = (maxRange - minRange) / binCount;

  // Compute bins dynamically based on current selected filtered values
  const bins = useMemo(() => {
    const list = Array.from({ length: binCount }, (_, i) => ({
      index: i,
      start: minRange + i * binWidth,
      end: minRange + (i + 1) * binWidth,
      count: 0,
    }));

    shiValues.forEach((val) => {
      // Find matching bin
      const binIdx = Math.min(
        binCount - 1,
        Math.max(0, Math.floor((val - minRange) / binWidth))
      );
      if (list[binIdx]) {
        list[binIdx].count += 1;
      }
    });

    return list;
  }, [shiValues, binWidth, binCount]);

  const maxCount = useMemo(() => {
    const counts = bins.map(b => b.count);
    return Math.max(1, ...counts);
  }, [bins]);

  // SVG Dimension values
  const width = 450;
  const height = 162;
  const paddingLeft = 34;
  const paddingRight = 10;
  const paddingTop = 15;
  const paddingBottom = 28;

  const chartWidth = width - paddingLeft - paddingRight;
  const chartHeight = height - paddingTop - paddingBottom;
  const barWidth = chartWidth / binCount;

  return (
    <div className="bg-slate-50/50 rounded-2xl p-3 border border-slate-200/40 relative">
      <div className="relative" style={{ height: `${height}px` }}>
        <svg
          viewBox={`0 0 ${width} ${height}`}
          width="100%"
          height="100%"
          className="overflow-visible"
        >
          {/* Y Axis Label (Rotated) */}
          <text
            transform="rotate(-90)"
            x={-(paddingTop + chartHeight / 2)}
            y={12}
            textAnchor="middle"
            className="fill-slate-450 font-sans text-[7px] font-bold tracking-wider uppercase select-none"
          >
            Häufigkeit (Messpunkte)
          </text>

          {/* X Axis Label */}
          <text
            x={paddingLeft + chartWidth / 2}
            y={height - 3}
            textAnchor="middle"
            className="fill-slate-500 font-sans text-[8px] font-bold tracking-wider uppercase select-none"
          >
            Boden-Gesundheits-Index (Soil Health Index - SHI)
          </text>

          {/* horizontal scale grids */}
          {[0, 0.25, 0.5, 0.75, 1.0].map((ratio) => {
            const y = paddingTop + chartHeight - ratio * chartHeight;
            const valLabel = Math.round(ratio * maxCount);
            return (
              <g key={ratio} className="select-none">
                <line
                  x1={paddingLeft}
                  y1={y}
                  x2={width - paddingRight}
                  y2={y}
                  stroke="#e2e8f0"
                  strokeWidth="0.8"
                  strokeDasharray="2 2"
                />
                <text
                  x={paddingLeft - 6}
                  y={y + 3}
                  textAnchor="end"
                  className="fill-slate-400 font-mono text-[8px] font-bold"
                >
                  {valLabel}
                </text>
              </g>
            );
          })}

          {/* Render individual thin histogram bars with spacing margins */}
          {bins.map((b) => {
            const barHeight = (b.count / maxCount) * chartHeight;
            const x = paddingLeft + b.index * barWidth + barWidth * 0.15; // 15% margin spacer on left
            const y = paddingTop + chartHeight - barHeight;
            const currentBarWidth = barWidth * 0.7; // Thin & spaced beautifully!

            const isHovered = b.index === hoveredBin;

            return (
              <rect
                key={b.index}
                x={x}
                y={y}
                width={currentBarWidth}
                height={Math.max(1, barHeight)}
                rx="2"
                fill={isHovered ? '#6366f1' : '#0e7490'} // Hover highlight color
                fillOpacity={isHovered ? 0.95 : 0.75}
                stroke={isHovered ? '#4f46e5' : '#0891b2'}
                strokeWidth="0.8"
                className="transition-all duration-200 cursor-pointer"
                onMouseEnter={() => setHoveredBin(b.index)}
                onMouseLeave={() => setHoveredBin(null)}
              />
            );
          })}

          {/* Bottom X-axis scale indicators */}
          {[1.5, 2.0, 2.5, 3.0, 3.5, 4.0].map((shiVal) => {
            const x = paddingLeft + ((shiVal - minRange) / (maxRange - minRange)) * chartWidth;
            return (
              <g key={shiVal} className="select-none">
                <line
                  x1={x}
                  y1={paddingTop + chartHeight}
                  x2={x}
                  y2={paddingTop + chartHeight + 3}
                  stroke="#cbd5e1"
                  strokeWidth="1"
                />
                <text
                  x={x}
                  y={height - 15}
                  textAnchor="middle"
                  className="fill-slate-500 font-mono text-[8.5px] font-semibold"
                >
                  {shiVal.toFixed(1)}
                </text>
              </g>
            );
          })}
        </svg>

        {/* Hover absolute tooltip box */}
        {hoveredBin !== null && bins[hoveredBin] && (
          <div className="absolute top-1 right-2 bg-slate-900/90 text-white rounded-lg p-1.5 px-2.5 text-[9px] font-medium leading-none z-10 font-sans shadow-md flex items-center gap-1">
            <span className="font-bold text-sky-300">
              SHI {bins[hoveredBin].start.toFixed(2)} - {bins[hoveredBin].end.toFixed(2)}:
            </span>
            <span className="font-extrabold text-white">
              {bins[hoveredBin].count} Standorte
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
