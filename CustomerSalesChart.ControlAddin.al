namespace DefaultPublisher.TestBC28;

controladdin "Customer Sales Chart"
{
    Scripts = 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js',
              'ControlAddIns/CustomerSalesChart/chart.js';
    StartupScript = 'ControlAddIns/CustomerSalesChart/startup.js';
    StyleSheets = 'ControlAddIns/CustomerSalesChart/chart.css';

    RequestedHeight = 360;
    MinimumHeight = 250;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    /// <summary>Déclenché quand le graphique est prêt à recevoir des données.</summary>
    event ControlReady();

    /// <summary>Déclenché au clic sur un élément du graphique.</summary>
    event CustomerClicked(CustomerNo: Text);

    /// <summary>Dessine le graphique à partir du JSON construit par "Customer Sales Analysis Mgt.".BuildChartData.</summary>
    procedure Render(ChartData: JsonObject);
}
