var cscChart = null;

var CSC_COLORS = [
    '#1F4E79', '#2E86C1', '#48C9B0', '#F4D03F', '#EB984E',
    '#E74C3C', '#8E44AD', '#5D6D7E', '#27AE60', '#D35400',
    '#16A085', '#7D3C98', '#2874A6', '#B7950B', '#A93226'
];

function cscShowMessage(text) {
    var msg = document.getElementById('cscMessage');
    if (!msg) { return; }
    msg.textContent = text || '';
    msg.hidden = !text;
}

function cscFormat(value) {
    return new Intl.NumberFormat(undefined, { maximumFractionDigits: 2 }).format(value);
}

function Render(chartData) {
    if (typeof Chart === 'undefined') {
        cscShowMessage('Impossible de charger la bibliothèque Chart.js (accès à cdnjs.cloudflare.com bloqué ?).');
        return;
    }

    var data = typeof chartData === 'string' ? JSON.parse(chartData) : chartData;
    var labels = data.labels || [];
    var keys = data.keys || [];
    var sourceSets = data.datasets || [];

    if (cscChart) {
        cscChart.destroy();
        cscChart = null;
    }

    if (labels.length === 0) {
        cscShowMessage('Aucune donnée pour les filtres sélectionnés.');
        return;
    }
    cscShowMessage('');

    var requestedType = data.chartType || 'bar';
    var horizontal = requestedType === 'horizontalBar';
    var circular = requestedType === 'pie' || requestedType === 'doughnut';
    var baseType = horizontal ? 'bar' : requestedType;

    var datasets = sourceSets.map(function (ds, index) {
        var color = CSC_COLORS[index === 0 ? 0 : 4];
        var set = {
            label: ds.label,
            data: ds.data,
            borderWidth: 1
        };

        if (circular) {
            set.backgroundColor = labels.map(function (_, i) { return CSC_COLORS[i % CSC_COLORS.length]; });
            set.borderColor = '#ffffff';
            return set;
        }

        if (ds.secondary) {
            set.type = horizontal ? 'bar' : 'line';
            set.backgroundColor = horizontal ? color + 'B3' : color;
            set.borderColor = color;
            set.borderWidth = 2;
            set.tension = 0.3;
            set.pointRadius = 3;
            if (horizontal) { set.xAxisID = 'x1'; } else { set.yAxisID = 'y1'; }
            set.order = 0;
        } else {
            set.backgroundColor = baseType === 'line' ? color + '33' : color + 'CC';
            set.borderColor = color;
            set.fill = baseType === 'line';
            set.tension = 0.3;
            set.order = 1;
        }
        return set;
    });

    var hasSecondary = sourceSets.some(function (ds) { return ds.secondary; });
    var scales = {};
    if (!circular) {
        var valueAxis = horizontal ? 'x' : 'y';
        var categoryAxis = horizontal ? 'y' : 'x';
        scales[categoryAxis] = { ticks: { autoSkip: false } };
        scales[valueAxis] = { beginAtZero: true, ticks: { callback: function (v) { return cscFormat(v); } } };
        if (hasSecondary) {
            var secondaryAxis = horizontal ? 'x1' : 'y1';
            scales[secondaryAxis] = {
                position: horizontal ? 'top' : 'right',
                beginAtZero: true,
                grid: { drawOnChartArea: false },
                ticks: { callback: function (v) { return cscFormat(v); } }
            };
        }
    }

    var ctx = document.getElementById('cscCanvas').getContext('2d');
    cscChart = new Chart(ctx, {
        type: baseType,
        data: { labels: labels, datasets: datasets },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: horizontal ? 'y' : 'x',
            animation: { duration: 900, easing: 'easeOutQuart' },
            interaction: { mode: circular ? 'nearest' : 'index', intersect: circular },
            scales: scales,
            plugins: {
                title: { display: !!data.title, text: data.title, font: { size: 14, weight: '600' } },
                legend: { position: circular ? 'right' : 'top' },
                tooltip: {
                    callbacks: {
                        label: function (item) {
                            var value = item.raw;
                            return ' ' + item.dataset.label + ' : ' + cscFormat(value);
                        }
                    }
                }
            },
            onClick: function (evt, elements) {
                if (!elements || elements.length === 0) { return; }
                var key = keys[elements[0].index];
                if (key) {
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('CustomerClicked', [key]);
                }
            },
            onHover: function (evt, elements) {
                evt.native.target.style.cursor = elements && elements.length ? 'pointer' : 'default';
            }
        }
    });
}
