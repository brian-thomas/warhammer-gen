

# ===========================================================================
# Filename    : WindowTools.pm
# Programmer  : Brian Thomas
# Description : general purpose GUI window tools
# Modules     : Exporter.pm
#
# RCS: $Id: WindowTools.pm,v 1.2 1999/01/25 17:18:14 socops Exp $
# ===========================================================================

package wintools;

use Tk;
use Tk::widgets qw(Button Label Radiobutton Entry Frame Menu Menubutton Text FileSelect Dialog DialogBox);
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( popup_msg_window 
              popup_notice
              popup_entry
              popup_file_select
              popup_yes_no_dialog
            );


sub popup_msg_window {
  my ($main,@msg) = @_;
  my $popup_width = 100;

  if(!$main) { print "ERROR: msg popup needs main window\n"; return; }
  chomp @msg;

  my $size = $#msg > 40 ? 42 : $#msg+3;
  my $top= $main->Toplevel;
  $top->configure(title => "Popup Window");

  # frame
  my $popup = $top->Frame()->pack(side => 'top', expand => 1, fill => 'both');

  # widgets
  my $text = $popup->Text(height => $size-1 );
  my $exit = $top->Button(text => "OK", command => sub {$top->destroy;});
  my $foo_height = $popup->Label();
  my $foo_width = $popup->Label();
  my $yscrollbar = $text->Scrollbar(-command => ['yview', $text]);

  #configure
  $text->configure(-yscrollcommand => ['set', $yscrollbar]);
  $text->configure(bg => 'black', fg => 'white');
  $exit->configure(bg => 'red', fg => 'black');
  $foo_height -> configure(height => $size);
  $foo_width -> configure(width => $popup_width);

  #pack it
  $foo_height->pack(side => 'left');
  $foo_width->pack(side => 'top');
  $text->pack(side => 'top', expand => 1, fill => 'both');
  $exit->pack(side => 'bottom');
  $yscrollbar->pack(-side=>'right', fill => 'y');

  for (@msg) {
    $text->insert('end', $_);
    $text->insert('end', "\n");
  }
}

# this dialog is mean to be temporary, it will
# disappear after a set amount of time
sub popup_notice {
  my ($main,$msg,$time,$title) = @_;
  if(!$main) { print "ERROR: popup dialog needs main window\n"; return; }
  if(!$title) { $title = "Popup Dialog"; }
  if(!$time) { $time = 1000; } # defaults to 1 sec 

  my $top = $main->Toplevel;
  $top->configure(title => $title);

  my $text = $top->Label(text => $msg )->pack;
  $text->configure(bg => 'black', fg => 'white');

  $top->after($time, sub { $top->destroy;});
}

# returns true if the user designates
# the yes answer. False return otherwise
sub popup_yes_no_dialog {
  my ($main,$msg,$title) = @_;

  if(!$main) { print "ERROR: Yes/No popup needs main window\n"; return; }
  if(!$title) { $title = "Yes/No Question"; }

  my @buttons;
  (@buttons) = (@buttons, "Yes");
  (@buttons) = (@buttons, "No");

  my $dialog = $main->Dialog(-title => $title, -text => $msg, -buttons => [@buttons]);
  my $selection = $dialog->Show;

  return $selection eq "Yes" ? 1 : 0;
}

sub popup_file_select {
  my ($main,$dir,$filter,$width,$height,$filelabel,$dirlabel,$filelistlabel,$dirlistlabel) = @_;
 
  $filter = "*" if !$filter;
  $dir = "." if !$dir;
 
  my $popup = $main->FileSelect(
                    -filter => "$filter",
                    -directory => $dir,
                    -takefocus => 1,
                   );
 
  # optional configuration
  $popup->configure(-width => $width) if $width;
  $popup->configure(-height => $height) if $height;
  $popup->configure(-filelabel => $filelabel) if $filelabel;
  $popup->configure(-filelistlabel => $filelistlabel) if $filelistlabel;
  $popup->configure(-dirlabel => $dirlabel) if $dirlabel;
  $popup->configure(-dirlistlabel => $dirlistlabel) if $dirlistlabel;
 
  my $selection = $popup->Show;
  return $selection;
}

sub popup_entry {
  my ($main,$msg,$default_value,$title,$ignore_val) = @_;
 
  if(!$main) { print "ERROR: Entry popup needs main window\n"; return; }
  if(!$title) { $title = "Entry Popup"; }
 
  my @buttons;
  (@buttons) = (@buttons, "Ok");
  (@buttons) = (@buttons, "Ignore");
 
  my $dialog = $main->DialogBox(
                      -title => $title, 
                      -buttons => [@buttons]
                 );
  my $label = $dialog->add('Label', -text => $msg);
  my $entry = $dialog->add('Entry'); 
  $entry->insert(0.0,$default_value) if ($default_value);
  $label->pack;
  $entry->pack;

  my $selection = $dialog->Show;
 
  my $ret_val = $selection eq 'Ok' ? $entry->get : $ignore_val;
  return $ret_val;
}

1;
