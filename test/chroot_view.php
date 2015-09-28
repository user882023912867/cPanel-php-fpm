<html>
<head>
  <title>PHP File Browser</title>
  <style type="text/css">
    .error{ color:red; font-weight:bold; }
  </style>
</head>
<body>

<?php
  // Explore the files via a web interface.
  $script = basename(__FILE__); // the name of this script
  $path = !empty($_REQUEST['path']) ? $_REQUEST['path'] : dirname(__FILE__); // the path the script should access

  echo "<h1>Directory Browser</h1>";
  echo "<p>Browsing Location: {$path}</p>";

  $directories = array();
  $files = array();

  // Check we are focused on a dir
  if (is_dir($path)) {
    chdir($path); // Focus on the dir
   if ($handle = opendir('.')) {
      while (($item = readdir($handle)) !== false) {
        // Loop through current directory and divide files and directorys
        if(is_dir($item)){
          array_push($directories, realpath($item));
        }
        else
        {
          array_push($files, ($item));
        }
   }
   closedir($handle); // Close the directory handle
   }
    else {
      echo "<p class=\"error\">Directory handle could not be obtained.</p>";
    }
  }
  else
  {
    echo "<p class=\"error\">Path is not a directory</p>";
  }

  // There are now two arrays that contians the contents of the path.

  // List the directories as browsable navigation
  echo "<h2>Navigation</h2>";
  echo "<ul>";
  foreach( $directories as $directory ){
    echo ($directory != $path) ? "<li><a href=\"{$script}?path={$directory}\">{$directory}</a></li>" : "";
  }
  echo "</ul>";

  echo "<h2>Files</h2>";
  echo "<ul>";
  foreach( $files as $file ){
    // Comment the next line out if you wish see hidden files while browsing
    if(preg_match("/^\./", $file) || $file == $script): continue; endif; // This line will hide all invisible files.
    echo '<li><a href="' . basename($file) . '" target="_blank">' . $file . '</a></li>';
  }
  echo "</ul>";
?>

</body>
</html>
