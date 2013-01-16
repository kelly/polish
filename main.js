require('coffee-script');
var polish = require('./lib/polish');


var html = polish('basic', {
  header: {
    template: 'templates/pre-header',
    locals: {
      content: 'test'
    }
  },
  content: '<div>test</div>',
  footer: {
    template: 'templates/footer',
    locals: {
      links: [],
      unsubscribe_url: 'dailymile 2014'
    }
  }
},
{ images: ['.header', '#template']}
);

console.log(html);


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
