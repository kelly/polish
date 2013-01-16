require('coffee-script');
var Polish = require('./lib/polish');


var polish = new Polish('basic', {
  header: '<div class="hellooo">blah</div>',
  content: '<div>test</div>',
  footer: {
    template: 'templates/footer',
    locals: {
      links: [],
      unsubscribe_url: 'dailymile 2014'
    }
  }
},
{ images: ['.header', '#template'] }
);


// // footer = polish.template('footer',
// //   unsubscribe_link: ''
// //   copyright: ''
// // ).toImage();

// // polish.append(header, body, footer);
// // polish.generate(inlineCss: true);

// var header = polish.template('header', { title: 'awesome' });
// var header2 = polish.template('header', { title: 'awesome' });

// polish.append(header, header2);
// polish.generate();



//   // polish.toImage('body')
//   // polish.exit()
// polish 'basic-layout', 
//   header:
//     template: 'header' 
//     locals: 
//   content:
//     html: ''
