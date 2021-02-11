<?php
//index.php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$error = '';

$csv_FID = '';
$csv_autonomia = '';
$csv_carretera = '';
$csv_causa = '';
$csv_fechahora_ = '';
$csv_hacia = '';
$csv_matricula = '';
$csv_nivel = '';
$csv_pk_final = '';
$csv_pk_inicial = '';
$csv_poblacion = '';
$csv_provincia = '';
$csv_ref_incide = '';
$csv_sentido = '';
$csv_tipo = '';
$csv_tipolocali = '';
$csv_version_in = '';
$csv_x = '';
$csv_X1 = '';
$csv_px = '';
$csv_y = '';
$csv_Y1 = '';
$csv_py = '';
$csv_xml_id = '';
$csv_xml_matche = '';
$csv_xml_parent = ''; //NULL
$csv_xml_pare_1 = ''; //NULL
$csv_actualizad = '';
$csv_query_date = '';

$filename = 'select/carretera.txt';
$eachlinesCarretera = file($filename, FILE_IGNORE_NEW_LINES);
$filename = 'select/poblacion.txt';
$eachlinesPoblacion = file($filename, FILE_IGNORE_NEW_LINES);
$filename = 'select/causa.txt';
$eachlinesCausa = file($filename, FILE_IGNORE_NEW_LINES);
$filename = 'select/provincia.txt';
$eachlinesProvincia = file($filename, FILE_IGNORE_NEW_LINES);

function clean_text($string)
{
    $string = trim($string);
    $string = stripslashes($string);
    $string = htmlspecialchars($string);
    return $string;
}

if (isset($_POST["submit"])) {
    $date = date('Y-m-dTh:i:s', time());
    if (empty($_POST["csv_y"])) {
        $error .= '<p><label class="text-danger">Please Enter latitude</label></p>';
    } else {
        $csv_y = clean_text($_POST["csv_y"]);
    }
    if (empty($_POST["csv_x"])) {
        $error .= '<p><label class="text-danger">Please Enter longitude</label></p>';
    } else {
        $csv_x = clean_text($_POST["csv_x"]);
    }

    $csv_autonomia = clean_text($_POST["autonomia"]);
    $csv_carretera = clean_text($_POST["carretera"]);
    $csv_causa = clean_text($_POST["causa"]);
    $csv_fechahora_ = $date;
    $csv_hacia = '';
    $csv_matricula = 'B';
    $csv_nivel = clean_text($_POST["nivel"]);
    $csv_pk_final = '';
    $csv_pk_inicial = '';
    $csv_poblacion = clean_text($_POST["poblacion"]);
    $csv_provincia = clean_text($_POST["provincia"]);
    $csv_ref_incide = '0T101068027';
    $csv_sentido = clean_text($_POST["sentido"]);
    $csv_tipo = clean_text($_POST["tipo"]);
    $csv_tipolocali = '0';
    $csv_version_in = '3';
    $csv_x = clean_text($_POST["csv_x"]);
    $csv_X1 = $csv_x;
    $csv_px = $csv_x;
    $csv_y = clean_text($_POST["csv_y"]);
    $csv_Y1 = $csv_y;
    $csv_py = $csv_y;
    $csv_xml_id = 'id-incidencia-40.01';
    $csv_xml_matche = 'incidencia';
    $csv_xml_parent = ''; //NULL
    $csv_xml_pare_1 = ''; //NULL
    $csv_actualizad = $date;
    $csv_query_date = $date;

    if ($error == '') {
        //Actualizamos el csv latest almacenado en el bucket
        //exec('gsutil cp gs://agaleratfm-bucket/incid_traf/incid_traf_latest.csv .');
        exec("Rscript r/generateIncidTrafWidget.R");
        //exec("./kk.sh");
        //sleep(3);
        $file_open = fopen("incid_traf_latest.csv", "a");
        $no_rows = count(file("incid_traf_latest.csv"));
        if ($no_rows > 1) {
            $no_rows = ($no_rows - 1) + 1;
        }
        $form_data = array(
            'FID' => $no_rows,
            'autonomia' => $csv_autonomia,
            'carretera' => $csv_carretera,
            'causa' => $csv_causa,
            'fechahora_' => $csv_fechahora_,
            'hacia' => $csv_hacia,
            'matricula' => $csv_matricula,
            'nivel' => $csv_nivel,
            'pk_final' => $csv_pk_final,
            'pk_inicial' => $csv_pk_inicial,
            'poblacion' => $csv_poblacion,
            'provincia' => $csv_provincia,
            'ref_incide' => $csv_ref_incide,
            'sentido' => $csv_sentido,
            'tipo' => $csv_tipo,
            'tipolocali' => $csv_tipolocali,
            'version_in' => $csv_version_in,
            'x' => $csv_x,
            'xml_id' => $csv_xml_id,
            'xml_matche' => $csv_xml_matche,
            'xml_parent' => $csv_xml_parent,
            'xml_pare_1' => $csv_xml_pare_1,
            'y' => $csv_y,
            'X1' => $csv_x,
            'Y1' => $csv_y,
            'actualizad' => $date,
            'px' => $csv_x,
            'py' => $csv_y,
            'query_date' => $date,
        );

        fputcsv($file_open, $form_data);
        $salida = shell_exec('rm -f /home/agalera/dead.letter');
        $error = '<label class="text-success">New traffic incident added</label>';
        $name = '';
        $email = '';
        $subject = '';
        $message = '';
    }
}

?>


<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="X-UA-Compatible" content="ie=edge" />
    <title>P</title>

    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Open+Sans:400,600" />
    <link rel="stylesheet" href="css/all.min.css" />
    <link rel="stylesheet" href="css/bootstrap.min.css" />
    <link rel="stylesheet" href="css/templatemo-style.css" />

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" />
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>

    <!--Para el fondo de los combo-box e iframe-->
    <!-- https://stackoverflow.com/questions/8366957/how-to-center-an-iframe-horizontally -->
    <style>
      select option {
        background-color: #6b6b6b;
        font-weight: bold;
        color: white;
      }
      img {
        max-width: 100%;
        max-height: 100%;
        display: block; /* remove extra space below image */
      }
      iframe {
        display: block;
        border-style:none;
      }
    }
    </style>
  </head>

  <body id="aboutPage">
    <div class="parallax-window" data-parallax="scroll" data-image-src="img/bg-01.jpg">
      <div class="container-fluid">
        <div class="row tm-brand-row">
          <div class="col-lg-4 col-11">
            <div class="tm-brand-container tm-bg-white-transparent">
              <i class="fas fa-2x fa-bus tm-brand-icon"></i>
              <div class="tm-brand-texts">
                <h1 class="tm-brand-name">BIDASIT<br>BigData in Transport Sector</h1>
                <p class="small">Master BigData UCM. Alejandro Galera</p>
              </div>
            </div>
          </div>
          <div class="col-lg-8 col-1">
            <div class="tm-nav">
              <nav class="navbar navbar-expand-lg navbar-light tm-bg-white-transparent tm-navbar">
                <button
                  class="navbar-toggler"
                  type="button"
                  data-toggle="collapse"
                  data-target="#navbarNav"
                  aria-controls="navbarNav"
                  aria-expanded="false"
                  aria-label="Toggle navigation">
                  <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                  <ul class="navbar-nav">
                    <li class="nav-item">
                      <div class="tm-nav-link-highlight"></div>
                      <a class="nav-link" style="color:#6b6b6b;font-size:20px;" href="index.html"
                        >Home</a
                      >
                    </li>
                    <li class="nav-item">
                      <div class="tm-nav-link-highlight"></div>
                      <a class="nav-link" style="color:#6b6b6b;font-size:20px;" href="services.html">BigData</a>
                    </li>
                    <li class="nav-item green-highlight active">
                      <div class="tm-nav-link-highlight"></div>
                      <a class="nav-link" style="color:#6b6b6b;font-size:20px;" href="#">
                        Register Incident<span class="sr-only">(current)</span>
                      </a>
                    </li>
<!--                    <li class="nav-item">
                      <div class="tm-nav-link-highlight"></div>
                      <a class="nav-link" href="testimonials.html">Testimonials</a>
                    </li>
-->
                    <li class="nav-item">
                      <div class="tm-nav-link-highlight"></div>
                      <a class="nav-link" style="color:#6b6b6b;font-size:20px;" href="contact.html">Contact</a>
                    </li>
                  </ul>
                </div>
              </nav>
            </div>
          </div>
        </div>

        <!-- About -->
        <section class="row" id="tmAbout">
          <header class="col-12 tm-about-header">
            <h2 class="text-uppercase text-center text-dark tm-about-page-title">New traffic incident DEMO</h2>
            <hr class="tm-about-title-hr">
          </header>

          <div class="col-lg-4">

            <div class="tm-bg-black-transparent tm-about-box">
              <div class="tm-about-number-container">0.1</div>
              <h3 class="tm-about-name">New incident detected</h3>
              <p class="tm-about-description">
                A new traffic incident could be notified by Police Department or official public transport drivers too filling a form like the one below.
              </p>
              <img src="img/incident.jpg" alt="Cloud Sky">
            </div>
          </div>

          <div class="col-lg-4">
            <div class="tm-bg-black-transparent tm-about-box">
              <div class="tm-about-number-container">0.2</div>
              <h3 class="tm-about-name">Append to current CSV incident file</h3>
              <p class="tm-about-description">
                New incident is appended to CSV previously taken from OpenData, processed in DataProc with PySpark and R.
              </p>
              <img src="img/incidentcsv.png" alt="Cloud Sky">
              <br/>
            </div>
          </div>

          <div class="col-lg-4">
            <div class="tm-bg-black-transparent tm-about-box">
              <div class="tm-about-number-container">0.3</div>
              <h3 class="tm-about-name">Map <br>updated</h3>
              <p class="tm-about-description">
                After having filled the form, the map will be updated with this new incident. If it's a blocking one, Public Sector companies could re-schedule routes.
              </p>
              <img src="img/incident_plot.png" alt="Cloud Sky">
            </div>
            <a href="#tmFeatures" class="btn btn-tertiary tm-btn-app-feature">Go to map</a>
          </div>
        </section>

        <!-- Incidence Form -->
        <section id="tmAppForm">
            <div class="row">
                <header class="col-12 text-center text-white tm-bg-black-transparent p-5 tm-app-header">
                    <h2 class="text-uppercase mb-3 tm-app-feature-header">New traffic Incidence</h2>
                    <form method="post">
                    <h3 align="center">Incidence Form</h3>
                    <?php echo $error; ?>
                    <!-- https://www.ine.es/daco/daco42/codmun/cod_ccaa.htm -->
                    <div class="form-group">
                      <label>Region</label>
                      <select id="autonomia" name="autonomia" class="form-control">
                        <option value="ANDALUCIA">ANDALUCIA</option>
                        <option value="ARAGON">ARAGON</option>
                        <option value="ASTURIAS">ASTURIAS</option>
                        <option value="BALEARES">BALEARES</option>
                        <option value="CANARIAS">CANARIAS</option>
                        <option value="CANTABRIA">CANTABRIA</option>
                        <option value="CASTILLA-LEON">CASTILLA-LEON</option>
                        <option value="CASTILLA-LA MANCHA">CASTILLA-LA MANCHA</option>
                        <option selected="selected" value="CATALUÑA">CATALUÑA</option>
                        <option value="COMUNITAT VALENCIANA">COMUNITAT VALENCIANA</option>
                        <option value="EXTREMADURA">EXTREMADURA</option>
                        <option value="GALICIA">GALICIA</option>
                        <option value="MADRID">MADRID</option>
                        <option value="MURCIA">MURCIA</option>
                        <option value="NAVARRA">NAVARRA</option>
                        <option value="PAIS VASCO">PAIS VASCO</option>
                        <option value="LA RIOJA">LA RIOJA</option>
                        <option value="CEUTA">CEUTA</option>
                        <option value="MELILLA">MELILLA</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Location</label>
                      <select id="poblacion" name="poblacion" class="form-control">
                        <option selected="selected" value="CREIXELL">CREIXELL</option>
                        <?php foreach ($eachlinesPoblacion as $linesPoblacion) { //add php code here
                          echo "<option poblacion='" . $linesPoblacion . "'>$linesPoblacion</option>";
                        }?>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Province</label>
                      <select id="provincia" name="provincia" class="form-control">
                        <option selected="selected" value="TARRAGONA">TARRAGONA</option>
                        <?php foreach ($eachlinesProvincia as $linesProvincia) { //add php code here
                          echo "<option provincia='" . $linesProvincia . "'>$linesProvincia</option>";
                        }?>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Road</label>
                      <select id="carretera" name="carretera" class="form-control">
                        <option selected="selected" value="N-340">N-340</option>
                        <?php foreach ($eachlinesCarretera as $linesCarretera) { //add php code here
                          echo "<option carretera='" . $linesCarretera . "'>$linesCarretera</option>";
                        }?>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Way, direction</label>
                      <select id="sentido" name="sentido" class="form-control">
                        <option value="SUR">SUR</option>
                        <option value="ESTE">ESTE</option>
                        <option value="NORTE">NORTE</option>
                        <option value="OESTE">OESTE</option>
                        <option selected="selected" value="AMBOS SENTIDOS">AMBOS SENTIDOS</option>
                        <option value="CRECIENTE DE LA KILOMETRICA">CRECIENTE DE LA KILOMETRICA</option>
                        <option value="DECRECIENTE DE LA KILOMETRICA">DECRECIENTE DE LA KILOMETRICA</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Reason</label>
                      <select id="causa" name="causa" class="form-control">
                        <option selected="selected" value="ACCIDENTE">ACCIDENTE</option>
                        <?php foreach ($eachlinesCausa as $linesCausa) { //add php code here
                          echo "<option causa='" . $linesCausa . "'>$linesCausa</option>";
                        }?>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Level</label>
                      <select id="nivel" name="nivel" class="form-control">
                        <option value="VERDE">VERDE</option>
                        <option value="AMARILLO">AMARILLO</option>
                        <option selected="selected" value="ROJO">ROJO</option>
                        <option value="NEGRO">NEGRO</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Type</label>
                      <select id="tipo" name="tipo" class="form-control">
                        <option value="CONO">CONO</option>
                        <option value="OBRAS">OBRAS</option>
                        <option value="RETENCION">RETENCION</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label>Latitude</label>
                      <input type="text" name="csv_y" placeholder="41.16703" class="form-control" value="<?php echo $csv_y; ?>" />
                    </div>
                    <div class="form-group">
                      <label>Longitude</label>
                      <input type="text" name="csv_x" class="form-control" placeholder="1.433811" value="<?php echo $csv_x; ?>" />
                    </div>
                    <div class="form-group" align="center">
                      <input type="submit" name="submit" class="btn btn-info" value="Submit" />
                    </div>
                  </header>
                </div>
        </section>
        <section id="tmFeatures">
            <iframe src="maps/htmlLeafletOSMIncidTraf.html" width="1260" height="800" frameborder="0">
              <p><a href="maps/htmlLeafletOSMIncidTraf.html">Mapa de incidentes de tráfico actualizado</a></p>
            </iframe>
            <br/>
            <div class="row">
                <div class="col-lg-6">
                    <div class="tm-bg-white-transparent tm-app-feature-box">
                        <div class="tm-app-feature-icon-container">
                            <i class="fas fa-3x fa-table tm-app-feature-icon"></i>
                        </div>
                        <div class="tm-app-feature-description-box">
                            <h3 class="mb-4 tm-app-feature-title">Re-schedule transports</h3>
                            <p class="tm-app-feature-description">Re-schedule transport timetable, organize and optimize resources, etc thanks to this dashboard map.</p>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6">
                    <div class="tm-bg-white-transparent tm-app-feature-box">
                        <div class="tm-app-feature-icon-container">
                            <i class="fas fa-3x fa-clock tm-app-feature-icon"></i>
                        </div>
                        <div class="tm-app-feature-description-box">
                            <h3 class="mb-4 tm-app-feature-title">Improve user experience</h3>
                            <p class="tm-app-feature-description">Improve user experience based on advertising, alerts, minimize traffic jams, etc.</p>
                        </div>
                    </div>
                </div>
            </div>

        </section>

        <!-- Page footer -->
        <footer class="row">
          <p class="col-12 text-white text-center tm-copyright-text">
            Copyright &copy; 2020 App Landing Page.
            Designed by <a href="#" class="tm-copyright-link">TemplateMo</a>
          </p>
        </footer>
      </div>
      <!-- .container-fluid -->
    </div>

    <script src="js/jquery.min.js"></script>
    <script src="js/parallax.min.js"></script>
    <script src="js/bootstrap.min.js"></script>
  </body>
</html>
