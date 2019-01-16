#!/usr/bin/perl -w 

# RCS: $Id: War_gen.pl,v 1.1 1999/03/20 17:45:33 thomas Exp thomas $

use strict;
use Tk;
use wintools;

my @army_units;
my $dont_display_unit_val = "Frame"; 

my $DEBUG_DATABASE = 0;
my $DEBUG = 0;

my $default_nrof_unit = 1;
my $default_weapon = "None";
my $default_weapon_damage = 0;  # will result in racial str being used
my $default_missile_weapon = "None";
my $default_missile_weapon_damage = 0;  # will result in racial str being used
my $default_armour = "None";

my $race_data_base = "whrstats.db";

my %tough_factor = ( 'A' => 0.333333, 'B' => 0.666666,
                     'C' => 1.0, 'D' => 1.333333, 
                     'E' => 1.666666, 'F' => 2.000000); 

# need to fold in the lower movement factor with the save factor into the 
# value of the unit armour
my %armor_factor = ( 'None' => 1.0, 
                     'Shield' => 1.4, 'Chain' => 1.4, 'BrestPlate' => 1.4, 
                     'Chain+Shield' => 1.6, 'BrestPlate+Shield' => 1.6, 'Plate' => 1.6, 
                     'Plate+Shield' => 1.867, 'Mithric' => 1.867, 
                     'Mithric+Shield' => 2.1667);

my %weapon_factor = ( 'None' => 0.5,
                      'Dagger' => 	0.75,
                      'Short Sword' => 	0.75,
                      'Light Sword' => 	0.75,
                      'Falchion' => 	0.75,
                      'Sabre' => 	0.75,
                      'Scimitar' => 	0.75,
                      'Mace' => 	1.0,
                      'Club' => 	1.0,
                      'Flail' => 	1.0,
                      'Long Sword' => 	1.0,
                      'Battle Axe' => 	1.0,
                      'Bastard Sword' => 	1.0,
                      'Short Spear' => 	1.15,
                      '2-Hand Club' => 	1.15,
                      '2-Hand Mace' => 	1.15,
                      '2-Hand Battle Axe' => 	1.15,
                      '2-Hand Sword' => 	1.15,
                      'Long Spear' => 	1.25,
                      'Halberd' => 	1.45,
                      'Pike' => 	1.65,
                      'Lance' => 	2.0
                     ); 

# this is the attack strength
my %bow_weapon_damage = ( 'None' => 0.0,
                      'Crossbow' => 	3.0,  # 3/4 cost as useable every other round IF moved 
                      'Sling' => 	2.0,
                      'Throwing Spear' => 	2.0,   # special, may fire only once or twice 
                      'Javalin' => 	2.0,   # special, may fire only once or twice 
                      'Short bow' => 	2.0,
                      'Infantry bow' => 	2.0,
                      'Darts' => 	2.0,
                      'Elven bow' => 	4.0,
                      'Horse bow' => 	2.0,
                      'Orcish bow' => 	2.0,
                      'Long bow' => 	3.0
                     ); 

my %bow_short_range = ( 'None' => 0,
                      'Crossbow' => 	16.0,
                      'Sling' => 	6.0,
                      'Throwing Spear' => 	1.0,   # special, may fire only once or twice 
                      'Javalin' => 	3.0,
                      'Short bow' => 	8.0,
                      'Infantry bow' => 	12.0,
                      'Darts' => 	1.0,
                      'Elven bow' => 	16.0,
                      'Horse bow' => 	8.0,
                      'Orcish bow' => 	8.0,
                      'Long bow' => 	16.0
                     ); 

my %bow_long_range = ( 'None' => 0,
                      'Crossbow' =>     32.0,
                      'Sling' =>        12.0,    
                      'Throwing Spear' =>       3.0,   # special, may fire only once or twice
                      'Javalin' =>      6.0,    
                      'Short bow' =>    16.0,    
                      'Infantry bow' =>         24.0,
                      'Darts' =>        3.0,
                      'Elven bow' =>    32.0,
                      'Horse bow' =>    16.0,
                      'Orcish bow' =>   16.0,
                      'Long bow' =>     32.0
                     );

# Argv loop
while ($_ = shift @ARGV) {
  # print $_, "\n";
  if(/-help/) { print "NO help available for $0 currently, sorry\n"; exit 0;}
  if(/-database/) { $race_data_base = shift @ARGV; }
  if(/-v/) { $DEBUG = 1; }
  if(/-V/) { $DEBUG_DATABASE = 1; }
}

# P R O G R A M   B E G I N S 


# load and initialize database of racial data 
  die "Aborting: can\'t find needed database $race_data_base" unless (-e $race_data_base);
  my ($stat_val_array_ref,$unit_hash_ref,$race_hash_ref) = 
       &load_unit_stats_data_base($race_data_base);
  my @stat_vals = @{$stat_val_array_ref};
  my %unit_stats = %{$unit_hash_ref};
  my %race_units = %{$race_hash_ref};

  dump_database() if $DEBUG_DATABASE;

  my ($main,$display) = &init_gui();

  MainLoop;

# S U B R O U T I N E S 

sub init_gui {

  my $mainWindow = new MainWindow();
  $mainWindow->title("Warhammer Army Builder Tool");

  #frames
  my $topFrame = $mainWindow->Frame()->pack(side => 'top', expand => 'yes', fill => 'both' );
  my $buttonFrame = $topFrame->Frame()->pack(side => 'top', expand => 'yes', fill => 'x');
  my $labelFrame = $topFrame->Frame()->pack(side => 'bottom', expand => 'yes', fill => 'x');
  my $ArmyDisplayFrame = $mainWindow->Frame()->pack(side => 'bottom', expand => 'yes', fill => 'both');

  # labels
  my $ArmyLabel =  $labelFrame->Label(text => "Current Army: ", 
                     bg => 'royalblue', fg => 'black')->pack(expand => 'yes', fill => 'x');

  # action buttons
  $buttonFrame->Button(text => "Load Army", 
                     bg => 'green', fg => 'black', 
                     command => \&load_army_from_file)->pack(side => 'left');
  $buttonFrame->Button(text => "Save Army", 
                     bg => 'green', fg => 'black', 
                     command => \&save_army_to_file)->pack(side => 'left');
  $buttonFrame->Button(text => "Add Unit To Army", 
                     bg => 'SeaGreen', fg => 'black', 
                     command => \&add_to_army)->pack(side => 'left');
  $buttonFrame->Button(text => "Print Army", 
                     bg => 'SeaGreen', fg => 'black', 
                     command => \&print_army)->pack(side => 'left');
  $buttonFrame->Button(text => "Quit", 
                     bg => 'red', fg => 'black', 
                     command => \&my_exit)->pack(side => 'left');

  return ($mainWindow,$ArmyLabel);
}

sub load_army_from_file {

  my $file = popup_file_select($main,".","*.wha");
  return unless (-e $file);

  #open file for reading
  open(FILE,$file) or die "ERROR: $0 can\'t open the $file\n";

  # reset the army units array
  clear_display();
  @army_units = ();

  my %current_unit;
  while (<FILE>) {
    chomp;
    if(/UNITEND/) {
        my %my_unit = %current_unit;
       (@army_units) = (@army_units, \%my_unit);
       next;
    }
    my @line_value = split ":", $_;
    $current_unit{$line_value[0]} = $line_value[1];
  }
  close FILE;

  display_army();
}

sub save_army_to_file {

  my $file = popup_file_select($main,".","*.wha");

  # append the WarHammer Army file suffix 
  my @names = split '\.', $file;
  $file .= ".wha" if (!$names[1]);

  #open file for writing, will clobber older files
  open(FILE,"> $file") or die "ERROR: $0 can\'t open the $file\n";

  foreach my $unit (@army_units) {
    foreach my $key (keys %{$unit}) {
       print FILE "$key:",%{$unit}->{$key},"\n" unless $key =~ "$dont_display_unit_val";
    }
    print FILE "UNITEND\n"; 
  }
  close FILE;
}

sub null_cmd { }

sub add_to_army { &gui_choose_race(); }

sub add_unit_to_army {
  my ($unit) = @_;

  my %army_unit = %{$unit_stats{$unit}};

  # add in default particulars (eg armour and weapon )
  # for this particular unit
  $army_unit{'Armour'} = $default_armour;
  $army_unit{'Weapon'} = $default_weapon;
  $army_unit{'Missile_Weapon'} = $default_missile_weapon;
  $army_unit{'Weapon_Damage'} = $default_weapon_damage;
  $army_unit{'Missile_Weapon_Damage'} = $default_missile_weapon_damage;
  $army_unit{'Nrof'} =  $default_nrof_unit;

  print "Adding $unit To Army \n" if $DEBUG;
  (@army_units) = (@army_units, \%army_unit);

  &display_army();
}

sub display_army {

  my $army_value = 0;
  &clear_display();

  foreach my $i (0 ... $#army_units) {
    my %unit = %{$army_units[$i]};

    next if defined $unit{'DONT_DISPLAY'};

    my $unit_value = sprintf("%8.2f",&get_unit_value(%unit));
    my $move = &find_unit_movement(%unit);

    $army_value += $unit_value;

    my $unitFrame = $main->Frame()->pack(side => 'bottom');

    %{$army_units[$i]}->{'Frame'} = $unitFrame;

    $unitFrame->Button(text => "Edit",
                        bg => 'SeaGreen', fg => 'white', 
                        command => [\&edit_armyunit, $i]
                       )->pack(side=> 'left');
    $unitFrame->Button(text => "Delete",
                        bg => 'red', fg => 'black', 
                        command => [\&delete_unit_from_army, $i]
                       )->pack(side=> 'left');
    $unitFrame->Button(text => sprintf("%3s",$unit{'Nrof'}), 
                        bg => 'black', fg => 'yellow', 
                        command => [\&increase_nrof_unit, \%{$army_units[$i]}->{'Nrof'}]
                       )->pack(side=> 'left');
    $unitFrame->Button(text => sprintf("%15s",$unit{'Name'}), 
                        bg => 'black', fg => 'yellow', 
                        command => [\&popup_unit_stat_display, %unit]
                       )->pack(side=> 'left');
    $unitFrame->Button(text => sprintf("Move: %3s", $move),
                        bg => 'black', fg => 'yellow', 
                        command => [\&decrease_nrof_unit, \%{$army_units[$i]}->{'Nrof'}, $i]
                       )->pack(side=> 'left');
    $unitFrame->Button(text => sprintf("Weapon: %12s",$unit{'Weapon'}),
                        bg => 'black', fg => 'yellow', 
                        command => sub { 
                                          &select_from_list_keys(\%{$army_units[$i]}->{'Weapon'},\%weapon_factor,\&display_army);
                                       } 
                       )->pack(side=> 'left');
    $unitFrame->Button(text => sprintf("Missile: %12s",$unit{'Missile_Weapon'}),
                        bg => 'black', fg => 'yellow', 
                        command => sub { 
                                          &select_from_list_keys2(
                                                                   \%{$army_units[$i]}->{'Missile_Weapon'},
                                                                   \%bow_weapon_damage,
                                                                   \%{$army_units[$i]}->{'Missile_Weapon_Damage'},
                                                                   \%bow_weapon_damage,
                                                                   \&display_army
                                                                  );
                                       } 
                       )->pack(side=> 'left');
    $unitFrame->Button(text => sprintf("Armour: %12s", $unit{'Armour'}), 
                        bg => 'black', fg => 'yellow', 
                        command => sub { 
                                          &select_from_list_keys(\%{$army_units[$i]}->{'Armour'},\%armor_factor,\&display_army);
                                       } 
                       )->pack(side=> 'left');
    $unitFrame->Button(text => "Value: $unit_value", 
                        bg => 'black', fg => 'yellow', 
                        command => \&null_cmd
                       )->pack(side=> 'left');

  }

  $display->configure(text => "Current Army:  Total Value=$army_value");

}

sub edit_armyunit {
  my ($unit_ref) = @_;

  my %army_unit = %{$army_units[$unit_ref]};

  my $popup = $main->Toplevel;
  $popup->configure(title => "Edit unit properties");

  my %entry_hash;
  for (sort keys %army_unit) {
     next if /$dont_display_unit_val/;
     my $frame = $popup->Frame()->pack(side => 'top');
     $frame->Label(text => $_, fg => 'yellow', bg => 'black'
                )->pack(side => 'left', anchor => 'w');
     $entry_hash{$_} = $frame->Entry()->pack(side => 'left');
     $entry_hash{$_}->insert('end', $army_unit{$_});
  }

  # insert the exit button
  $popup->Button(text => 'Finished', fg => 'white', bg => 'SeaGreen',
                    command => sub { 
                                     %{$army_units[$unit_ref]} =
                                       &change_unit_properites(\%army_unit, \%entry_hash); 
                                     &display_army();
                                     $popup->destroy 
                                   }
                   )->pack(side => 'top', anchor => 'w');

}

sub change_unit_properites {
  my($unit_ref, $entry_hash_ref) = @_; 
  my (%army_unit) = %{$unit_ref};
  my (%entry_hash) = %{$entry_hash_ref};

  for (keys %entry_hash) {
    $army_unit{$_} = $entry_hash{$_}->get();
  }

  return %army_unit;
}

sub delete_unit_from_army {
  my ($unit_ref) = @_;

  # we have to display BEFORE removing, or we will
  # wind up leaving the unit in display (cant find
  # it in the army_units array so it doesnt get deleted!)
  # Thats why we use this special DONT_DISPLAY variable
  %{$army_units[$unit_ref]}->{'DONT_DISPLAY'} = 1;
  display_army();

  # now splice it out of the array
  splice @army_units, $unit_ref, 1;

}

sub decrease_nrof_unit {
  my ($var_ref,$unit_ref) = @_;

  &delete_unit_from_army($unit_ref) if(--${$var_ref} < 1); 
  display_army();
}

sub increase_nrof_unit {
  my ($var_ref) = @_;

  ${$var_ref}++; 
  display_army();
}

sub select_from_list_keys {
  my ($var_ref,$list_ref,$exec_ref) = @_;

  my %list = %{$list_ref};
  my $popup = $main->Toplevel;
  $popup->configure(title => "Click on item to select");

  # Try to make the 'None' option appear first
  $popup->Button(text => 'None', 
                 fg => 'yellow', bg => 'black',
                 command => sub {  ${$var_ref} = 'None'; $popup->destroy; &{$exec_ref} if $exec_ref; }
                )->pack(side => 'top', anchor => 'w') if defined $list{'None'};

  foreach my $item (sort keys %list ) {
    $popup->Button(text => $item, 
                    fg => 'yellow', bg => 'black',
                    command => sub {  ${$var_ref} = $item; $popup->destroy; &{$exec_ref} if $exec_ref; }
                   )->pack(side => 'top', anchor => 'w') unless $item eq 'None';
  }

}

sub select_from_list_keys2 {
  my ($var_ref,$list_ref,$var_ref2,$list_ref2,$exec_ref) = @_;

  my %list = %{$list_ref};
  my %list2 = %{$list_ref2};

  my $popup = $main->Toplevel;
  $popup->configure(title => "Click on item to select");
  
  # Try to make the 'None' option appear first
  $popup->Button(text => 'None', 
                 fg => 'yellow', bg => 'black',
                 command => sub {  ${$var_ref} = 'None'; $popup->destroy; &{$exec_ref} if $exec_ref; }
                )->pack(side => 'top', anchor => 'w') if defined $list{'None'};
  
  foreach my $item (sort keys %list ) {
    $popup->Button(text => $item, 
                    fg => 'yellow', bg => 'black',
                    command => sub {  ${$var_ref} = $item; 
                                      ${$var_ref2} = $list2{$item};
                                      $popup->destroy; 
                                      &{$exec_ref} if $exec_ref; 
                                    }
                   )->pack(side => 'top', anchor => 'w') unless $item eq 'None';
  }
}

sub clear_display {
  for (@army_units) {
    %{$_}->{'Frame'}->destroy if defined %{$_}->{'Frame'}; 
  }
}

sub my_exit {
   exit 0;
}

sub find_unit_movement {
  my (%stats) = @_;
  # my %stats = %{$unit_stats{$unit}};

  my $armor = $stats{'Armour'};
  my @movement = split "/", $stats{'Move'};
  
  $armor = 'None' if !defined $stats{'Armour'};

  my $ret_val = $armor eq 'None' ? $movement[0] : $movement[1];
  return $ret_val;
}

sub base_melee_value {
  my (%stats) = @_;
 
  # my %stats = %{$unit_stats{$unit}};

  my ($armor) = $stats{'Armour'};
  my ($weapon) = $stats{'Weapon'};
  # my ($weapon_damage) = $stats{'Weapon_Damage'};

  # Movement times Weapon skill sets initial value
  my $movement = &find_unit_movement(%stats);
  my $value = ($stats{'WSkill'}/3) * $movement;

  # Weapon Factor
  $value *= $weapon_factor{$weapon} if $weapon;

  # Damage Factor
  # my $damage_factor = ($weapon_damage ? $weapon_damage : $stats{'WStr'});
  my $damage_factor =  $stats{'WStr'};
  $value *= $damage_factor > 3 ? ($damage_factor/3) + ($damage_factor-3)/6 : $damage_factor/3; 

  # Armor Factor
  $value *= $armor_factor{$armor} if($armor);

  return $value; 
}

sub base_missile_value {
  my (%stats) = @_;

  my ($missile_weapon) = $stats{'Missile_Weapon'};
  my ($missile_weapon_damage) = $stats{'Missile_Weapon_Damage'} ? $stats{'Missile_Weapon_Damage'} : 
                    $bow_weapon_damage{$missile_weapon};

  # Range averaged wi/ unit movement times Bow skill sets initial value
  my $range_factor = ($bow_short_range{$missile_weapon}/2) + ($bow_long_range{$missile_weapon}/3) +
                         (&find_unit_movement(%stats)/2);
  my $value = ($stats{'BSkill'}/3) * ($range_factor/2);

  # modify by the bow damage
  my $damage_factor = $missile_weapon_damage; # ? $missile_weapon_damage : $stats{'BStr'});
  $value *= $damage_factor > 3 ? ($damage_factor/3) + ($damage_factor-3)/6 : $damage_factor/3; 

  return $value; 
}

sub noncmbt_intrinsic_value {
  my (%stats) = @_;

 # print "GOT UNIT: $unit\n";
 # my %stats = %{$unit_stats{$unit}};

  my $nrof_attacks = $stats{'Attacks'}; 
  my $initiative_factor = 0;

  foreach my $attack (0 .. $nrof_attacks) {
   last if $stats{'Init'} <= $attack;
   $initiative_factor += (($stats{'Init'} - $attack)/3) if (($stats{'Init'} - $attack) > 0);
  } 

  my $value = $stats{'Wounds'}; 
  $value *= $nrof_attacks;
  $value *= $initiative_factor;
  $value *= $tough_factor{$stats{'Tough'}};
  $value *= $stats{'RouteFac'}; 

  return $value;
}

sub dump_database {
  foreach my $unit_name (keys %unit_stats) {
    my %unit = %{$unit_stats{$unit_name}};
    print "[";
    foreach my $val (@stat_vals) {
      print $unit{$val}, " ";
    }
    print "]\t";
    my $intrinsic_value = &noncmbt_intrinsic_value(%unit);
    my $basic_melee_value = &base_melee_value(%unit);
    my $value = $intrinsic_value * $basic_melee_value;
    printf("\tIntrinsic:%8.2f Melee:%8.2f Value:%8.2f\n",$intrinsic_value,$basic_melee_value,$value);
  }
  exit 0;
}

sub get_unit_value {
  my (%unit) = @_;

  my $intrinsic_value = &noncmbt_intrinsic_value(%unit);
  my $basic_melee_value = &base_melee_value(%unit);
  my $basic_missile_value = &base_missile_value(%unit);
  my $value = $intrinsic_value * ($basic_melee_value + $basic_missile_value);

  return $value * $unit{'Nrof'};
}

sub load_unit_stats_data_base {
  my ($file) = @_;
  my %unit_stats_hash;
  my %race_units;
  my $got_init_info=0;
  my @vals;

  open(FILE, $file) || die "$0 aborting: can\'t find $file";

  foreach my $line (<FILE>) {

    chomp $line;
    next if ($line =~ /^#/); # hash means its a comment line

    # snarf data from the line
    my @line_data = split('\|', $line);

    # first line defines order of the stats
    if(!$got_init_info) {
      push(@vals,@line_data);
      $got_init_info = 1;
      next;
    }

    # now build a race stat hash 
    my %stats_hash;
    my $i=0;
    foreach my $val (@vals) {
      my $data;
      # trim off the leading and trailing spaces 
      my @array = split "|", $line_data[$i++];
      while(<@array>) { next if(/ /); $data .= $_; }
      $stats_hash{$val} = $data;
    }

    # set the race_data 
    $unit_stats_hash{"$line_data[0]"} = \%stats_hash;
    $race_units{$stats_hash{'Group'}} = 1;

  }

  close FILE;

  # group all of the units by race
  foreach my $race (keys %race_units) {
    my @tmparray = ();
    foreach my $unit (keys %unit_stats_hash) {
      (@tmparray) = (@tmparray,$unit) if ( $unit_stats_hash{$unit}->{'Group'} eq $race); 
    } 
    $race_units{$race} = \@tmparray;
  }
 
  return (\@vals,\%unit_stats_hash,\%race_units);
}

sub gui_choose_unit {
  my ($race,$popup,$button_list_ref) = @_;

  my $unit_ref;
  my @button_list = @{$button_list_ref};

  for (@button_list) { $_->destroy; }

  # my $popup = $main->Toplevel;
  $popup->configure(title => "Click on unit to Select");

  foreach my $unit (@{$race_units{$race}}) {
     # print "UNIT:$unit\n";
     $popup->Button(text => $unit, fg => 'yellow', bg => 'black', 
                    command => sub {  add_unit_to_army($unit) ;$popup->destroy }
                   )->pack(side => 'top', anchor => 'w');
  }

}

sub gui_choose_race {

  my @button_list;

  my $popup = $main->Toplevel;
  $popup->configure(title => "Click on race to Select");

  foreach my $race (keys %race_units) {
    # my $name = %{$unit_stats{$unit}}->{'Name'};
    (@button_list) = (@button_list, $popup->Button(text => $race, fg => 'yellow', bg => 'black', 
                    command => sub { &gui_choose_unit($race,$popup,\@button_list); }
                   )->pack(side => 'top', anchor => 'w')); 
  }
}


sub popup_unit_stat_display {
  my (%unit) = @_;

  my $popup = $main->Toplevel;
  $popup->configure(title => "Unit Stat Display");

  my $stat_display = $popup->Text()->pack(side => 'top'); 

  foreach my $val (@stat_vals) {
    $stat_display->insert('end', "$val:\t$unit{$val}\n");
  }

  $popup->Button(text => 'Exit', fg => 'yellow', bg => 'black', 
                    command => sub { $popup->destroy }
                   )->pack(side => 'top', anchor => 'w'); 

}

sub print_army {

  my $filename = "dump.txt";

  if (1) {
    # should set FILE to be stderr
    # open(FILE, "| more");
    open (FILE, ">$filename") || die "$0 aborts: can\'t open dump file \n";
  } else {
    open (FILE, ">$filename") || die "$0 aborts: can\'t open dump file \n";
  }

  print FILE "\n\t A R M Y  C O M P O S I T I O N \n";
  print FILE " #  ";
  my $buf = sprintf("%21s","Name ");
  print FILE $buf;
  foreach my $val (@stat_vals) {
      next if $val eq 'Name';
      next if $val eq 'Group';
      next if $val eq 'RouteFac';
      $buf = sprintf("%8s ",$val);
      print FILE $buf;
  }
  print FILE "\n";

  # print out the stats
  for (@army_units) {
    $buf = sprintf("%3s|",%{$_}->{'Nrof'});
    print FILE $buf;
    $buf = sprintf("%20s|",%{$_}->{'Name'});
    print FILE $buf;
    foreach my $val (@stat_vals) {
      next if $val eq 'Name';
      next if $val eq 'Group';
      next if $val eq 'RouteFac';
      if($val eq 'Move'){
         $buf =  sprintf("%7s |", &find_unit_movement(%{$_}));
      } else { 
        $buf =  sprintf("%7s |",%{$_}->{$val});
      }
      print FILE $buf;
    }
    print FILE "\n";
  }
  print FILE "\n";

  # print out the weapons/missile weapons and armour
  print FILE "\n\t E Q U I P M E N T  S T A T S\n";
  $buf = sprintf("%21s%21s%21s%13s","Name ","Weapon ","Missile Weapon ","Armour ");
  print FILE "$buf\n";
  for (@army_units) {
    $buf = sprintf("%20s|",%{$_}->{'Name'});
    print FILE $buf;

    $buf =  sprintf("%12s [dam:%s] ",%{$_}->{'Weapon'}, %{$_}->{'WStr'});
    print FILE $buf;

    $buf =  sprintf("%12s [dam:%s] ",%{$_}->{'Missile_Weapon'}, %{$_}->{'Missile_Weapon_Damage'});
    print FILE $buf;

    $buf =  sprintf("%12s ",%{$_}->{'Armour'});
    print FILE "$buf \n";
  }
  print FILE "\n";

  close FILE;

  system ("lpr $filename");

}


